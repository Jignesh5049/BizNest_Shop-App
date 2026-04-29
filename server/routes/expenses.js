const express = require('express');
const router = express.Router();
const Expense = require('../models/Expense');
const Business = require('../models/Business');
const { protect } = require('../middleware/auth');

router.use(protect);

const getBusinessId = async (userId) => {
    const business = await Business.findOne({ userId });
    return business?._id;
};

const parseDateInput = (value) => {
    if (!value) return null;

    if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
        const [year, month, day] = value.split('-').map(Number);
        return new Date(year, month - 1, day);
    }

    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
};

const toStartOfDay = (value) =>
    new Date(value.getFullYear(), value.getMonth(), value.getDate(), 0, 0, 0, 0);

const toEndOfDay = (value) =>
    new Date(value.getFullYear(), value.getMonth(), value.getDate(), 23, 59, 59, 999);

// @route   GET /api/expenses
// @desc    Get all expenses
// @access  Private
router.get('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { category, startDate, endDate, limit = 50 } = req.query;
        const query = { businessId };

        if (category) query.category = category;
        if (startDate || endDate) {
            const parsedStart = parseDateInput(startDate);
            const parsedEnd = parseDateInput(endDate);
            if (startDate && !parsedStart) {
                return res.status(400).json({ message: 'Invalid startDate' });
            }
            if (endDate && !parsedEnd) {
                return res.status(400).json({ message: 'Invalid endDate' });
            }
            if (parsedStart && parsedEnd && parsedStart > parsedEnd) {
                return res.status(400).json({ message: 'startDate cannot be after endDate' });
            }

            query.date = {};
            if (parsedStart) query.date.$gte = toStartOfDay(parsedStart);
            if (parsedEnd) query.date.$lte = toEndOfDay(parsedEnd);
        }

        const expenses = await Expense.find(query)
            .sort({ date: -1 })
            .limit(parseInt(limit));

        res.json(expenses);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/expenses/summary
// @desc    Get expense summary by category
// @access  Private
router.get('/summary', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { month, year, startDate, endDate } = req.query;
        let rangeStart;
        let rangeEnd;

        if (startDate || endDate) {
            const parsedStart = parseDateInput(startDate);
            const parsedEnd = parseDateInput(endDate);
            if (startDate && !parsedStart) {
                return res.status(400).json({ message: 'Invalid startDate' });
            }
            if (endDate && !parsedEnd) {
                return res.status(400).json({ message: 'Invalid endDate' });
            }
            if (parsedStart && parsedEnd && parsedStart > parsedEnd) {
                return res.status(400).json({ message: 'startDate cannot be after endDate' });
            }

            rangeStart = parsedStart ? toStartOfDay(parsedStart) : new Date('2000-01-01T00:00:00.000Z');
            rangeEnd = parsedEnd ? toEndOfDay(parsedEnd) : new Date();
        } else {
            const now = new Date();
            const targetMonth = month ? parseInt(month, 10) - 1 : now.getMonth();
            const targetYear = year ? parseInt(year, 10) : now.getFullYear();
            rangeStart = new Date(targetYear, targetMonth, 1);
            rangeEnd = new Date(targetYear, targetMonth + 1, 0, 23, 59, 59, 999);
        }

        const summary = await Expense.aggregate([
            {
                $match: {
                    businessId,
                    date: { $gte: rangeStart, $lte: rangeEnd }
                }
            },
            {
                $group: {
                    _id: '$category',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            }
        ]);

        const totalExpenses = summary.reduce((acc, cat) => acc + cat.total, 0);

        res.json({
            summary,
            totalExpenses,
            startDate: rangeStart,
            endDate: rangeEnd
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/expenses
// @desc    Create expense
// @access  Private
router.post('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const expense = await Expense.create({
            ...req.body,
            businessId
        });

        res.status(201).json(expense);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/expenses/:id
// @desc    Update expense
// @access  Private
router.put('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const expense = await Expense.findOneAndUpdate(
            { _id: req.params.id, businessId },
            req.body,
            { new: true, runValidators: true }
        );

        if (!expense) {
            return res.status(404).json({ message: 'Expense not found' });
        }

        res.json(expense);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   DELETE /api/expenses/:id
// @desc    Delete expense
// @access  Private
router.delete('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const expense = await Expense.findOneAndDelete({ _id: req.params.id, businessId });

        if (!expense) {
            return res.status(404).json({ message: 'Expense not found' });
        }

        res.json({ message: 'Expense deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
