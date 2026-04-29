const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const Business = require('../models/Business');
const Review = require('../models/Review');
const { protect } = require('../middleware/auth');

router.use(protect);

// Helper to get business ID
const getBusinessId = async (userId) => {
    const business = await Business.findOne({ userId });
    return business?._id;
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

// @route   GET /api/products
// @desc    Get all products
// @access  Private
router.get('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const products = await Product.find({ businessId, isActive: true }).sort({ createdAt: -1 });
        const hydratedProducts = await applyRatingStats(products);
        res.json(hydratedProducts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/products/:id
// @desc    Get single product
// @access  Private
router.get('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const product = await Product.findOne({ _id: req.params.id, businessId });

        if (!product) {
            return res.status(404).json({ message: 'Product not found' });
        }

        res.json(product);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/products
// @desc    Create product
// @access  Private
router.post('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const product = await Product.create({
            ...req.body,
            businessId
        });

        res.status(201).json(product);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/products/:id
// @desc    Update product
// @access  Private
router.put('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const product = await Product.findOneAndUpdate(
            { _id: req.params.id, businessId },
            { ...req.body, updatedAt: Date.now() },
            { new: true, runValidators: true }
        );

        if (!product) {
            return res.status(404).json({ message: 'Product not found' });
        }

        res.json(product);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   DELETE /api/products/:id
// @desc    Delete product (soft delete)
// @access  Private
router.delete('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const product = await Product.findOneAndUpdate(
            { _id: req.params.id, businessId },
            { isActive: false },
            { new: true }
        );

        if (!product) {
            return res.status(404).json({ message: 'Product not found' });
        }

        res.json({ message: 'Product deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PATCH /api/products/:id/stock
// @desc    Update stock
// @access  Private
router.patch('/:id/stock', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const { quantity, operation } = req.body;

        const product = await Product.findOne({ _id: req.params.id, businessId });
        if (!product) {
            return res.status(404).json({ message: 'Product not found' });
        }

        if (operation === 'add') {
            product.stock += quantity;
        } else if (operation === 'subtract') {
            product.stock = Math.max(0, product.stock - quantity);
        } else {
            product.stock = quantity;
        }

        await product.save();
        res.json(product);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
