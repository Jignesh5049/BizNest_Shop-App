const express = require('express');
const router = express.Router();
const Customer = require('../models/Customer');
const Order = require('../models/Order');
const Business = require('../models/Business');
const { protect } = require('../middleware/auth');

router.use(protect);

const getBusinessId = async (userId) => {
    const business = await Business.findOne({ userId });
    return business?._id;
};

// @route   GET /api/customers
// @desc    Get all customers
// @access  Private
router.get('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const customers = await Customer.find({ businessId }).sort({ createdAt: -1 });
        res.json(customers);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/customers/:id
// @desc    Get single customer with orders
// @access  Private
router.get('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const customer = await Customer.findOne({ _id: req.params.id, businessId });

        if (!customer) {
            return res.status(404).json({ message: 'Customer not found' });
        }

        // Get customer's orders
        const orders = await Order.find({ customerId: customer._id }).sort({ createdAt: -1 }).limit(10);

        res.json({ customer, orders });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/customers
// @desc    Create customer
// @access  Private
router.post('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const customer = await Customer.create({
            ...req.body,
            businessId
        });

        res.status(201).json(customer);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/customers/:id
// @desc    Update customer
// @access  Private
router.put('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const customer = await Customer.findOneAndUpdate(
            { _id: req.params.id, businessId },
            { ...req.body, updatedAt: Date.now() },
            { new: true, runValidators: true }
        );

        if (!customer) {
            return res.status(404).json({ message: 'Customer not found' });
        }

        res.json(customer);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   DELETE /api/customers/:id
// @desc    Delete customer
// @access  Private
router.delete('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const customer = await Customer.findOneAndDelete({ _id: req.params.id, businessId });

        if (!customer) {
            return res.status(404).json({ message: 'Customer not found' });
        }

        res.json({ message: 'Customer deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
