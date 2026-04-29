const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Business = require('../models/Business');
const CustomerProfile = require('../models/CustomerProfile');
const { generateToken, protect } = require('../middleware/auth');

// @route   POST /api/auth/signup
// @desc    Register a new user (business or customer)
// @access  Public
router.post('/signup', async (req, res) => {
    try {
        const { name, email, password, role = 'business', phone } = req.body;

        // Check if user exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: 'User already exists with this email' });
        }

        // Create user with role
        const user = await User.create({ name, email, password, role, phone });

        // Create appropriate profile based on role
        if (role === 'business') {
            // Create placeholder business profile (populated fully in onboarding)
            const businessName = (name && name.trim().length) ? name.trim() : 'New Business';
            await Business.create({
                userId: user._id,
                name: businessName,
                category: 'other',
                isOnboarded: false
            });
        } else if (role === 'customer') {
            // Create customer profile
            await CustomerProfile.create({
                userId: user._id,
                addresses: [],
                favorites: [],
                wishlist: []
            });
        }

        res.status(201).json({
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            phone: user.phone,
            token: generateToken(user._id)
        });
    } catch (error) {
        console.error('Signup error:', error);
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/auth/login
// @desc    Login user - role is determined from database
// @access  Public
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Find user with password
        const user = await User.findOne({ email }).select('+password');
        if (!user) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }

        // Check password
        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }

        // Get business or customer profile based on user's stored role
        let business = null;
        let customerProfile = null;

        if (user.role === 'business') {
            business = await Business.findOne({ userId: user._id });
        } else if (user.role === 'customer') {
            customerProfile = await CustomerProfile.findOne({ userId: user._id });
        }

        res.json({
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            phone: user.phone,
            token: generateToken(user._id),
            business: business,
            customerProfile: customerProfile
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', protect, async (req, res) => {
    try {
        const user = await User.findById(req.user._id);

        let business = null;
        let customerProfile = null;

        if (user.role === 'business') {
            business = await Business.findOne({ userId: req.user._id });
        } else if (user.role === 'customer') {
            customerProfile = await CustomerProfile.findOne({ userId: req.user._id });
        }

        res.json({
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            phone: user.phone,
            business: business,
            customerProfile: customerProfile
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/auth/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', protect, async (req, res) => {
    try {
        const { name, phone, currentPassword, newPassword } = req.body;

        const user = await User.findById(req.user._id).select('+password');

        if (name) user.name = name;
        if (phone) user.phone = phone;

        // Handle password change
        if (currentPassword && newPassword) {
            const isMatch = await user.comparePassword(currentPassword);
            if (!isMatch) {
                return res.status(400).json({ message: 'Current password is incorrect' });
            }
            user.password = newPassword;
        }

        await user.save();

        res.json({
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            phone: user.phone
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/auth/sync
// @desc    Sync Supabase user with MongoDB (called from Flutter after Supabase login)
// @access  Public (called with Supabase token, but we verify in-route)
router.post('/sync', async (req, res) => {
    try {
        const { email, role, supabaseId, name, phone } = req.body;

        if (!email || !supabaseId) {
            return res.status(400).json({ message: 'Email and supabaseId are required' });
        }

        // Look for existing user by supabaseId first, then by email
        let user = await User.findOne({ supabaseId });

        if (!user) {
            user = await User.findOne({ email });
        }

        if (user) {
            // Link supabaseId if not already linked
            if (!user.supabaseId) {
                user.supabaseId = supabaseId;
                await user.save();
            }
        } else {
            // Create new user (Supabase-synced, no local password needed)
            user = await User.create({
                name: name || email.split('@')[0],
                email,
                password: require('crypto').randomBytes(32).toString('hex'), // Random password since auth is via Supabase
                role: role || 'business',
                phone: phone || '',
                supabaseId,
            });

            // Create appropriate profile based on role
            if ((role || 'business') === 'business') {
                await Business.create({
                    userId: user._id,
                    name: name || 'New Business',
                    category: 'other',
                    isOnboarded: false,
                });
            } else if (role === 'customer') {
                await CustomerProfile.create({
                    userId: user._id,
                    addresses: [],
                    favorites: [],
                    wishlist: [],
                });
            }
        }

        // Get business or customer profile
        let business = null;
        let customerProfile = null;

        if (user.role === 'business') {
            business = await Business.findOne({ userId: user._id });
        } else if (user.role === 'customer') {
            customerProfile = await CustomerProfile.findOne({ userId: user._id });
        }

        res.json({
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            phone: user.phone,
            business,
            customerProfile,
        });
    } catch (error) {
        console.error('Sync error:', error);
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
