const express = require('express');
const router = express.Router();
const Business = require('../models/Business');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Customer = require('../models/Customer');
const CustomerProfile = require('../models/CustomerProfile');
const Review = require('../models/Review');
const SupportTicket = require('../models/SupportTicket');
const { protect } = require('../middleware/auth');

const updateProductRating = async (productId) => {
    const stats = await Review.aggregate([
        { $match: { productId } },
        { $group: { _id: '$productId', average: { $avg: '$rating' }, count: { $sum: 1 } } }
    ]);

    const ratingAverage = stats[0]?.average || 0;
    const ratingCount = stats[0]?.count || 0;

    await Product.findByIdAndUpdate(productId, {
        ratingAverage: Math.round(ratingAverage * 10) / 10,
        ratingCount
    });
};

const applyRatingStats = async (products) => {
    if (!products.length) return products;

    const productIds = products.map(product => product._id);
    const stats = await Review.aggregate([
        { $match: { productId: { $in: productIds } } },
        { $group: { _id: '$productId', average: { $avg: '$rating' }, count: { $sum: 1 } } }
    ]);

    const statsMap = new Map(
        stats.map(item => [item._id.toString(), item])
    );

    const updates = [];
    const hydrated = products.map(product => {
        const data = product.toObject ? product.toObject() : product;
        const stat = statsMap.get(product._id.toString());
        const ratingAverage = stat ? Math.round(stat.average * 10) / 10 : 0;
        const ratingCount = stat ? stat.count : 0;

        if ((product.ratingAverage || 0) !== ratingAverage || (product.ratingCount || 0) !== ratingCount) {
            updates.push({
                updateOne: {
                    filter: { _id: product._id },
                    update: { ratingAverage, ratingCount }
                }
            });
        }

        return {
            ...data,
            ratingAverage,
            ratingCount
        };
    });

    if (updates.length) {
        await Product.bulkWrite(updates);
    }

    return hydrated;
};

// ==================== PUBLIC ROUTES ====================

// @route   GET /api/store/businesses
// @desc    Get all businesses (public)
// @access  Public
router.get('/businesses', async (req, res) => {
    try {
        const { category, search } = req.query;

        let query = {};

        if (category && category !== 'all') {
            query.category = category;
        }

        if (search) {
            query.name = { $regex: search, $options: 'i' };
        }

        const businesses = await Business.find(query)
            .select('name category description logo contact address')
            .sort({ createdAt: -1 });

        res.json(businesses);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/store/businesses/:id
// @desc    Get single business with products
// @access  Public
router.get('/businesses/:id', async (req, res) => {
    try {
        const business = await Business.findById(req.params.id)
            .select('name category description logo contact address socialLinks');

        if (!business) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const products = await Product.find({
            businessId: req.params.id,
            isActive: true
        }).select('name description category sellingPrice stock unit image ratingAverage ratingCount');

        const hydratedProducts = await applyRatingStats(products);

        res.json({ business, products: hydratedProducts });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/store/products/:id
// @desc    Get single product details
// @access  Public
router.get('/products/:id', async (req, res) => {
    try {
        const product = await Product.findById(req.params.id)
            .populate('businessId', 'name logo contact');

        if (!product) {
            return res.status(404).json({ message: 'Product not found' });
        }

        res.json(product);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/store/products/:id/reviews
// @desc    Get product reviews (public)
// @access  Public
router.get('/products/:id/reviews', async (req, res) => {
    try {
        const reviews = await Review.find({ productId: req.params.id })
            .select('customerName rating comment createdAt')
            .sort({ createdAt: -1 });

        res.json(reviews);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/store/all-products
// @desc    Get all products from all businesses (for home page)
// @access  Public
router.get('/all-products', async (req, res) => {
    try {
        const { category, search, sort = 'newest', limit = 20 } = req.query;

        let query = {
            isActive: { $ne: false }
        };

        if (category && category !== 'all') {
            query.category = { $regex: category, $options: 'i' };
        }

        if (search) {
            query.$or = [
                { name: { $regex: search, $options: 'i' } },
                { description: { $regex: search, $options: 'i' } }
            ];
        }

        // Handle sorting
        let sortOption = {};
        switch (sort) {
            case 'price_low':
                sortOption = { sellingPrice: 1, price: 1 };
                break;
            case 'price_high':
                sortOption = { sellingPrice: -1, price: -1 };
                break;
            case 'name_asc':
                sortOption = { name: 1 };
                break;
            case 'newest':
            default:
                sortOption = { createdAt: -1 };
                break;
        }

        const products = await Product.find(query)
            .populate('businessId', 'name logo category')
            .sort(sortOption)
            .limit(parseInt(limit));

        const hydratedProducts = await applyRatingStats(products);

        res.json(hydratedProducts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// ==================== PROTECTED CUSTOMER ROUTES ====================

// Middleware to ensure user is a customer
const customerOnly = async (req, res, next) => {
    if (req.user.role !== 'customer') {
        return res.status(403).json({ message: 'Access denied. Customer only.' });
    }
    next();
};

// @route   GET /api/store/products/:id/reviews/eligibility
// @desc    Check review eligibility for a product
// @access  Private (Customer)
router.get('/products/:id/reviews/eligibility', protect, customerOnly, async (req, res) => {
    try {
        const product = await Product.findById(req.params.id).select('businessId');
        if (!product) {
            return res.status(404).json({ message: 'Product not found' });
        }

        const hasCompletedOrder = await Order.exists({
            customerUserId: req.user._id,
            status: 'completed',
            'items.productId': req.params.id
        });

        if (!hasCompletedOrder) {
            return res.json({ canReview: false, reason: 'Purchase required' });
        }

        const alreadyReviewed = await Review.exists({
            productId: req.params.id,
            customerUserId: req.user._id
        });

        if (alreadyReviewed) {
            return res.json({ canReview: false, reason: 'Already reviewed' });
        }

        res.json({ canReview: true });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/store/products/:id/reviews
// @desc    Create product review (must have completed purchase)
// @access  Private (Customer)
router.post('/products/:id/reviews', protect, customerOnly, async (req, res) => {
    try {
        const { rating, comment } = req.body;

        const product = await Product.findById(req.params.id).select('businessId');
        if (!product) {
            return res.status(404).json({ message: 'Product not found' });
        }

        if (!rating || rating < 1 || rating > 5) {
            return res.status(400).json({ message: 'Rating must be between 1 and 5' });
        }

        const hasCompletedOrder = await Order.exists({
            customerUserId: req.user._id,
            status: 'completed',
            'items.productId': req.params.id
        });

        if (!hasCompletedOrder) {
            return res.status(403).json({ message: 'You can only review products you have purchased' });
        }

        const existingReview = await Review.findOne({
            productId: req.params.id,
            customerUserId: req.user._id
        });

        if (existingReview) {
            return res.status(400).json({ message: 'You have already reviewed this product' });
        }

        const review = await Review.create({
            productId: req.params.id,
            businessId: product.businessId,
            customerUserId: req.user._id,
            customerName: req.user.name,
            rating,
            comment
        });

        await updateProductRating(review.productId);

        res.status(201).json(review);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/store/orders
// @desc    Create a new order
// @access  Private (Customer)
router.post('/orders', protect, customerOnly, async (req, res) => {
    try {
        const { businessId, items, deliveryAddress, notes, paymentMethod } = req.body;

        const normalizePaymentMethod = (value) => {
            const input = (value || 'cash').toString().trim().toLowerCase();
            if (input === 'cod' || input === 'cash_on_delivery' || input === 'cash on delivery') {
                return 'cash';
            }

            const allowed = new Set(['cash', 'upi', 'card', 'bank', 'other']);
            return allowed.has(input) ? input : 'cash';
        };

        const normalizedPaymentMethod = normalizePaymentMethod(paymentMethod);

        // Validate business exists
        const business = await Business.findById(businessId);
        if (!business) {
            return res.status(404).json({ message: 'Business not found' });
        }

        // Find or create customer record for this business
        let customer = await Customer.findOne({
            businessId,
            email: req.user.email
        });

        if (!customer) {
            customer = await Customer.create({
                businessId,
                name: req.user.name,
                email: req.user.email,
                phone: req.user.phone,
                address: deliveryAddress
            });
        }

        // Calculate totals
        let subtotal = 0;
        let totalCost = 0;
        const orderItems = [];

        for (const item of items) {
            const product = await Product.findById(item.productId);
            if (!product) {
                return res.status(404).json({ message: `Product not found: ${item.productId}` });
            }

            const itemTotal = product.sellingPrice * item.quantity;
            subtotal += itemTotal;
            totalCost += product.costPrice * item.quantity;

            orderItems.push({
                productId: product._id,
                name: product.name,
                quantity: item.quantity,
                price: product.sellingPrice,
                image: product.image,
                costPrice: product.costPrice,
                total: itemTotal
            });
        }

        const order = await Order.create({
            businessId,
            customerId: customer._id,
            customerUserId: req.user._id,
            items: orderItems,
            subtotal,
            total: subtotal,
            totalCost,
            deliveryAddress,
            notes,
            paymentMethod: normalizedPaymentMethod,
            status: 'pending',
            paymentStatus: 'unpaid'
        });

        // Update customer stats
        customer.orderCount += 1;
        customer.totalSpent += subtotal;
        customer.lastOrderDate = new Date();
        await customer.save();

        res.status(201).json(order);
    } catch (error) {
        console.error('Order creation error:', error);
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/store/orders
// @desc    Get customer's orders
// @access  Private (Customer)
router.get('/orders', protect, customerOnly, async (req, res) => {
    try {
        const { status } = req.query;

        let query = { customerUserId: req.user._id };
        if (status && status !== 'all') {
            query.status = status;
        }

        const orders = await Order.find(query)
            .populate('businessId', 'name logo')
            .sort({ createdAt: -1 });

        const orderData = orders.map(order => order.toObject());
        const productIds = new Set();

        orderData.forEach(order => {
            order.items?.forEach(item => {
                if (!item.image && item.productId) {
                    productIds.add(item.productId.toString());
                }
            });
        });

        if (productIds.size) {
            const products = await Product.find({ _id: { $in: Array.from(productIds) } })
                .select('_id image images imageUrl thumbnail photo productImage media');

            const pickImageUrl = (value) => {
                if (!value) return '';
                if (typeof value === 'string') return value;
                if (typeof value === 'object') {
                    return value.url || value.src || value.secure_url || value.image || '';
                }
                return '';
            };

            const imageMap = new Map(products.map(product => {
                const firstImage =
                    pickImageUrl(product.image) ||
                    pickImageUrl(product.imageUrl) ||
                    pickImageUrl(product.thumbnail) ||
                    pickImageUrl(product.photo) ||
                    pickImageUrl(product.productImage) ||
                    pickImageUrl(product.media && product.media.url) ||
                    (Array.isArray(product.images) && product.images.length
                        ? pickImageUrl(product.images[0])
                        : '');

                if (product.name && /bread|pav/i.test(product.name)) {
                    console.log('\n=== DEBUG: Bread/Pav Product ===');
                    console.log('Product:', product.name, '(ID:', product._id, ')');
                    console.log('image field:', JSON.stringify(product.image));
                    console.log('imageUrl field:', JSON.stringify(product.imageUrl));
                    console.log('images field:', JSON.stringify(product.images));
                    console.log('Resolved firstImage:', firstImage);
                    console.log('================================\n');
                }

                if (product.name && /bread|pav/i.test(product.name)) {
                    console.log('\n=== DEBUG: Bread/Pav Product (Detail) ===');
                    console.log('Product:', product.name, '(ID:', product._id, ')');
                    console.log('image field:', JSON.stringify(product.image));
                    console.log('imageUrl field:', JSON.stringify(product.imageUrl));
                    console.log('images field:', JSON.stringify(product.images));
                    console.log('Resolved firstImage:', firstImage);
                    console.log('================================\n');
                }

                return [product._id.toString(), firstImage || ''];
            }));

            orderData.forEach(order => {
                order.items = order.items?.map(item => ({
                    ...item,
                    image: item.image || imageMap.get(item.productId?.toString()) || ''
                }));
            });
        }

        res.json(orderData);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/store/orders/:id
// @desc    Get single order details
// @access  Private (Customer)
router.get('/orders/:id', protect, customerOnly, async (req, res) => {
    try {
        const order = await Order.findOne({
            _id: req.params.id,
            customerUserId: req.user._id
        }).populate('businessId', 'name logo contact');

        if (!order) {
            return res.status(404).json({ message: 'Order not found' });
        }

        const orderData = order.toObject();
        const productIds = new Set();

        orderData.items?.forEach(item => {
            if (!item.image && item.productId) {
                productIds.add(item.productId.toString());
            }
        });

        if (productIds.size) {
            const products = await Product.find({ _id: { $in: Array.from(productIds) } })
                .select('_id image images imageUrl thumbnail photo productImage media');

            const pickImageUrl = (value) => {
                if (!value) return '';
                if (typeof value === 'string') return value;
                if (typeof value === 'object') {
                    return value.url || value.src || value.secure_url || value.image || '';
                }
                return '';
            };

            const imageMap = new Map(products.map(product => {
                const firstImage =
                    pickImageUrl(product.image) ||
                    pickImageUrl(product.imageUrl) ||
                    pickImageUrl(product.thumbnail) ||
                    pickImageUrl(product.photo) ||
                    pickImageUrl(product.productImage) ||
                    pickImageUrl(product.media && product.media.url) ||
                    (Array.isArray(product.images) && product.images.length
                        ? pickImageUrl(product.images[0])
                        : '');

                return [product._id.toString(), firstImage || ''];
            }));

            orderData.items = orderData.items?.map(item => ({
                ...item,
                image: item.image || imageMap.get(item.productId?.toString()) || ''
            }));
        }

        res.json(orderData);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/store/orders/:id/cancel
// @desc    Cancel an order
// @access  Private (Customer)
router.put('/orders/:id/cancel', protect, customerOnly, async (req, res) => {
    try {
        const order = await Order.findOne({
            _id: req.params.id,
            customerUserId: req.user._id
        });

        if (!order) {
            return res.status(404).json({ message: 'Order not found' });
        }

        if (order.status !== 'pending') {
            return res.status(400).json({ message: 'Only pending orders can be cancelled' });
        }

        order.status = 'cancelled';
        await order.save();

        res.json(order);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/store/orders/:id/reorder
// @desc    Re-order a previous order
// @access  Private (Customer)
router.post('/orders/:id/reorder', protect, customerOnly, async (req, res) => {
    try {
        const originalOrder = await Order.findOne({
            _id: req.params.id,
            customerUserId: req.user._id
        });

        if (!originalOrder) {
            return res.status(404).json({ message: 'Order not found' });
        }

        // Create new order with same items
        const newOrder = await Order.create({
            businessId: originalOrder.businessId,
            customerId: originalOrder.customerId,
            customerUserId: req.user._id,
            items: originalOrder.items,
            subtotal: originalOrder.subtotal,
            total: originalOrder.total,
            totalCost: originalOrder.totalCost,
            deliveryAddress: originalOrder.deliveryAddress,
            paymentMethod: originalOrder.paymentMethod,
            status: 'pending',
            paymentStatus: 'unpaid'
        });

        // Update customer stats
        if (originalOrder.customerId) {
            const customer = await Customer.findById(originalOrder.customerId);
            if (customer) {
                customer.orderCount += 1;
                customer.totalSpent += originalOrder.total;
                customer.lastOrderDate = new Date();
                await customer.save();
            }
        }

        res.status(201).json(newOrder);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// ==================== SUPPORT / FEEDBACK ====================

// @route   GET /api/store/support
// @desc    Get customer support replies
// @access  Private (Customer)
router.get('/support', protect, customerOnly, async (req, res) => {
    try {
        const tickets = await SupportTicket.find({ customerUserId: req.user._id })
            .populate('orderId', 'orderNumber createdAt')
            .populate('productId', 'name')
            .sort({ createdAt: -1 });

        res.json(tickets);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/store/support
// @desc    Submit support request or feedback for a completed order
// @access  Private (Customer)
router.post('/support', protect, customerOnly, async (req, res) => {
    try {
        const { type, subject, message, orderId, issueType, productId } = req.body;

        if (!message || !message.trim()) {
            return res.status(400).json({ message: 'Message is required' });
        }

        if (!orderId) {
            return res.status(400).json({ message: 'Order is required for support requests' });
        }

        const order = await Order.findOne({
            _id: orderId,
            customerUserId: req.user._id
        }).select('businessId status items orderNumber');

        if (!order) {
            return res.status(404).json({ message: 'Order not found' });
        }

        if (order.status !== 'completed') {
            return res.status(400).json({ message: 'Support requests are available only for completed orders' });
        }

        if (productId) {
            const hasProduct = order.items.some(item => item.productId.toString() === productId);
            if (!hasProduct) {
                return res.status(400).json({ message: 'Selected product is not in this order' });
            }
        }

        const business = await Business.findById(order.businessId);
        if (!business) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const ticket = await SupportTicket.create({
            businessId: order.businessId,
            orderId,
            productId: productId || undefined,
            customerUserId: req.user._id,
            customerName: req.user.name,
            customerEmail: req.user.email,
            type: type || 'support',
            issueType: issueType || 'complaint',
            subject: subject || `Order ${order.orderNumber} - ${issueType || 'complaint'}`,
            message
        });

        res.status(201).json(ticket);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// ==================== FAVORITES ROUTES ====================

// @route   GET /api/store/favorites
// @desc    Get customer's favorites
// @access  Private (Customer)
router.get('/favorites', protect, customerOnly, async (req, res) => {
    try {
        const profile = await CustomerProfile.findOne({ userId: req.user._id })
            .populate({
                path: 'favorites',
                populate: { path: 'businessId', select: 'name logo' }
            });

        // Return full product details
        const favorites = profile?.favorites || [];
        const favoritesList = favorites.map(product => {
            if (!product) return null;
            return {
                _id: product._id,
                product: {
                    _id: product._id,
                    name: product.name,
                    description: product.description,
                    sellingPrice: product.sellingPrice,
                    price: product.sellingPrice,
                    image: product.image,
                    images: product.image ? [product.image] : [],
                    stock: product.stock,
                    category: product.category,
                    businessId: product.businessId
                }
            };
        }).filter(Boolean);

        res.json(favoritesList);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/store/favorites/:productId
// @desc    Add to favorites
// @access  Private (Customer)
router.post('/favorites/:productId', protect, customerOnly, async (req, res) => {
    try {
        const profile = await CustomerProfile.findOne({ userId: req.user._id });

        if (!profile.favorites.includes(req.params.productId)) {
            profile.favorites.push(req.params.productId);
            await profile.save();
        }

        res.json({ message: 'Added to favorites' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   DELETE /api/store/favorites/:productId
// @desc    Remove from favorites
// @access  Private (Customer)
router.delete('/favorites/:productId', protect, customerOnly, async (req, res) => {
    try {
        const profile = await CustomerProfile.findOne({ userId: req.user._id });

        profile.favorites = profile.favorites.filter(
            id => id.toString() !== req.params.productId
        );
        await profile.save();

        res.json({ message: 'Removed from favorites' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// ==================== ADDRESS ROUTES ====================

// @route   GET /api/store/addresses
// @desc    Get customer's addresses
// @access  Private (Customer)
router.get('/addresses', protect, customerOnly, async (req, res) => {
    try {
        const profile = await CustomerProfile.findOne({ userId: req.user._id });
        res.json(profile?.addresses || []);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/store/addresses
// @desc    Add new address
// @access  Private (Customer)
router.post('/addresses', protect, customerOnly, async (req, res) => {
    try {
        const { label, street, city, state, pincode, isDefault } = req.body;

        const profile = await CustomerProfile.findOne({ userId: req.user._id });

        if (isDefault) {
            profile.addresses.forEach(addr => addr.isDefault = false);
        }

        profile.addresses.push({ label, street, city, state, pincode, isDefault });
        await profile.save();

        res.status(201).json(profile.addresses);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/store/addresses/:id
// @desc    Update address
// @access  Private (Customer)
router.put('/addresses/:id', protect, customerOnly, async (req, res) => {
    try {
        const { label, street, city, state, pincode, isDefault } = req.body;

        const profile = await CustomerProfile.findOne({ userId: req.user._id });

        const address = profile.addresses.id(req.params.id);
        if (!address) {
            return res.status(404).json({ message: 'Address not found' });
        }

        if (isDefault) {
            profile.addresses.forEach(addr => addr.isDefault = false);
        }

        Object.assign(address, { label, street, city, state, pincode, isDefault });
        await profile.save();

        res.json(profile.addresses);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   DELETE /api/store/addresses/:id
// @desc    Delete address
// @access  Private (Customer)
router.delete('/addresses/:id', protect, customerOnly, async (req, res) => {
    try {
        const profile = await CustomerProfile.findOne({ userId: req.user._id });

        profile.addresses = profile.addresses.filter(
            addr => addr._id.toString() !== req.params.id
        );
        await profile.save();

        res.json(profile.addresses);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// ==================== CUSTOMER DASHBOARD ====================

// @route   GET /api/store/dashboard
// @desc    Get customer dashboard stats
// @access  Private (Customer)
router.get('/dashboard', protect, customerOnly, async (req, res) => {
    try {
        const orders = await Order.find({ customerUserId: req.user._id });

        const totalOrders = orders.length;
        const activeOrders = orders.filter(o =>
            ['pending', 'confirmed'].includes(o.status)
        ).length;
        const completedOrders = orders.filter(o => o.status === 'completed').length;
        const totalSpent = orders
            .filter(o => o.status === 'completed')
            .reduce((sum, o) => sum + o.total, 0);

        const recentOrders = await Order.find({ customerUserId: req.user._id })
            .populate('businessId', 'name logo')
            .sort({ createdAt: -1 })
            .limit(5);

        res.json({
            stats: {
                totalOrders,
                activeOrders,
                completedOrders,
                totalSpent
            },
            recentOrders
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
