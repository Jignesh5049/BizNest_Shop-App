const express = require('express');
const router = express.Router();
const Review = require('../models/Review');
const Business = require('../models/Business');
const { protect } = require('../middleware/auth');

router.use(protect);

const getBusinessId = async (userId) => {
    const business = await Business.findOne({ userId });
    return business?._id;
};

// @route   GET /api/reviews
// @desc    Get reviews for business (optional product filter)
// @access  Private (Business)
router.get('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const query = { businessId };
        if (req.query.productId) query.productId = req.query.productId;

        const reviews = await Review.find(query)
            .populate('productId', 'name')
            .sort({ createdAt: -1 });

        res.json(reviews);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
