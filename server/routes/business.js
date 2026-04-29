const express = require('express');
const router = express.Router();
const Business = require('../models/Business');
const { protect } = require('../middleware/auth');

// All routes are protected
router.use(protect);

// @route   GET /api/business
// @desc    Get current user's business
// @access  Private
router.get('/', async (req, res) => {
    try {
        const business = await Business.findOne({ userId: req.user._id });
        if (!business) {
            return res.status(404).json({ message: 'Business not found' });
        }
        res.json(business);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/business
// @desc    Create or update business profile
// @access  Private
router.post('/', async (req, res) => {
    try {
        const { name, category, description, contact, address, logo, socialLinks } = req.body;

        let business = await Business.findOne({ userId: req.user._id });

        if (business) {
            // Update existing business
            business.name = name || business.name;
            business.category = category || business.category;
            business.description = description || business.description;
            business.contact = contact || business.contact;
            business.address = address || business.address;
            business.logo = logo || business.logo;
            business.socialLinks = socialLinks || business.socialLinks;
            business.isOnboarded = true;

            await business.save();
        } else {
            // Create new business
            business = await Business.create({
                userId: req.user._id,
                name,
                category,
                description,
                contact,
                address,
                logo,
                socialLinks,
                isOnboarded: true
            });
        }

        res.json(business);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/business
// @desc    Update business profile
// @access  Private
router.put('/', async (req, res) => {
    try {
        const business = await Business.findOneAndUpdate(
            { userId: req.user._id },
            { ...req.body, updatedAt: Date.now() },
            { new: true, runValidators: true }
        );

        if (!business) {
            return res.status(404).json({ message: 'Business not found' });
        }

        res.json(business);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
