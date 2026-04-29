const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const Product = require('../models/Product');
const Customer = require('../models/Customer');
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
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
};

const toEndOfDay = (value) =>
    new Date(value.getFullYear(), value.getMonth(), value.getDate(), 23, 59, 59, 999);

const getDateFilter = (query) => {
    const { month, year, startDate, endDate } = query;
    const hasCustomRange = Boolean(startDate || endDate);

    if (hasCustomRange) {
        const parsedStart = parseDateInput(startDate);
        const parsedEnd = parseDateInput(endDate);
        if (startDate && !parsedStart) {
            const error = new Error('Invalid startDate');
            error.statusCode = 400;
            throw error;
        }
        if (endDate && !parsedEnd) {
            const error = new Error('Invalid endDate');
            error.statusCode = 400;
            throw error;
        }
        if (parsedStart && parsedEnd && parsedStart > parsedEnd) {
            const error = new Error('startDate cannot be after endDate');
            error.statusCode = 400;
            throw error;
        }

        const rangeStart = parsedStart || new Date('2000-01-01T00:00:00.000Z');
        const rangeEnd = parsedEnd ? toEndOfDay(parsedEnd) : new Date();
        return {
            rangeStart,
            rangeEnd,
            hasCustomRange,
            anchorMonth: new Date(rangeEnd.getFullYear(), rangeEnd.getMonth(), 1)
        };
    }

    const now = new Date();
    const targetMonth = month ? parseInt(month, 10) - 1 : now.getMonth();
    const targetYear = year ? parseInt(year, 10) : now.getFullYear();
    const rangeStart = new Date(targetYear, targetMonth, 1);
    const rangeEnd = new Date(targetYear, targetMonth + 1, 0, 23, 59, 59, 999);

    return {
        rangeStart,
        rangeEnd,
        hasCustomRange,
        anchorMonth: new Date(targetYear, targetMonth, 1)
    };
};

const toMonthKey = (year, month) => `${year}-${String(month).padStart(2, '0')}`;

const monthLabel = (year, month) => {
    const monthDate = new Date(year, month - 1, 1);
    const shortMonth = monthDate.toLocaleString('default', { month: 'short' });
    return `${shortMonth} ${String(year).slice(-2)}`;
};

// @route   GET /api/analytics/dashboard
// @desc    Get dashboard stats
// @access  Private
router.get('/dashboard', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { rangeStart, rangeEnd, hasCustomRange } = getDateFilter(req.query);
        let previousRangeStart;
        let previousRangeEnd;

        if (hasCustomRange) {
            const rangeMs = Math.max(24 * 60 * 60 * 1000, rangeEnd.getTime() - rangeStart.getTime() + 1);
            previousRangeEnd = new Date(rangeStart.getTime() - 1);
            previousRangeStart = new Date(previousRangeEnd.getTime() - rangeMs + 1);
        } else {
            previousRangeStart = new Date(rangeStart.getFullYear(), rangeStart.getMonth() - 1, 1);
            previousRangeEnd = new Date(rangeStart.getFullYear(), rangeStart.getMonth(), 0, 23, 59, 59, 999);
        }

        // Total revenue (all time)
        const totalRevenueResult = await Order.aggregate([
            { $match: { businessId, paymentStatus: 'paid' } },
            { $group: { _id: null, total: { $sum: '$total' } } }
        ]);
        const totalRevenue = totalRevenueResult[0]?.total || 0;

        // This month's revenue
        const monthlyRevenueResult = await Order.aggregate([
            { $match: { businessId, paymentStatus: 'paid', createdAt: { $gte: rangeStart, $lte: rangeEnd } } },
            { $group: { _id: null, total: { $sum: '$total' }, profit: { $sum: '$profit' } } }
        ]);
        const monthlyRevenue = monthlyRevenueResult[0]?.total || 0;
        const monthlyProfit = monthlyRevenueResult[0]?.profit || 0;

        // Last month's revenue for comparison
        const lastMonthRevenueResult = await Order.aggregate([
            { $match: { businessId, paymentStatus: 'paid', createdAt: { $gte: previousRangeStart, $lte: previousRangeEnd } } },
            { $group: { _id: null, total: { $sum: '$total' } } }
        ]);
        const lastMonthRevenue = lastMonthRevenueResult[0]?.total || 0;

        // Total orders
        const totalOrders = await Order.countDocuments({ businessId, status: { $ne: 'cancelled' } });
        const monthlyOrders = await Order.countDocuments({
            businessId,
            status: { $ne: 'cancelled' },
            createdAt: { $gte: rangeStart, $lte: rangeEnd }
        });

        // This month's expenses
        const monthlyExpensesResult = await Expense.aggregate([
            { $match: { businessId, date: { $gte: rangeStart, $lte: rangeEnd } } },
            { $group: { _id: null, total: { $sum: '$amount' } } }
        ]);
        const monthlyExpenses = monthlyExpensesResult[0]?.total || 0;

        // Net profit
        const netProfit = monthlyProfit - monthlyExpenses;

        // Product stats
        const totalProducts = await Product.countDocuments({ businessId, isActive: true });
        const lowStockProducts = await Product.countDocuments({ businessId, isActive: true, stock: { $lte: 5, $gt: 0 } });
        const outOfStockProducts = await Product.countDocuments({ businessId, isActive: true, stock: 0 });

        // Customer stats
        const totalCustomers = await Customer.countDocuments({ businessId });
        const repeatCustomers = await Customer.countDocuments({ businessId, isRepeatCustomer: true });

        // Pending orders
        const pendingOrders = await Order.countDocuments({ businessId, status: 'pending' });
        const unpaidOrders = await Order.countDocuments({ businessId, paymentStatus: 'unpaid', status: { $ne: 'cancelled' } });

        res.json({
            revenue: {
                total: totalRevenue,
                monthly: monthlyRevenue,
                lastMonth: lastMonthRevenue,
                growth: lastMonthRevenue > 0 ? ((monthlyRevenue - lastMonthRevenue) / lastMonthRevenue * 100).toFixed(1) : 0
            },
            profit: {
                monthly: monthlyProfit,
                net: netProfit
            },
            expenses: {
                monthly: monthlyExpenses
            },
            orders: {
                total: totalOrders,
                monthly: monthlyOrders,
                pending: pendingOrders,
                unpaid: unpaidOrders
            },
            products: {
                total: totalProducts,
                lowStock: lowStockProducts,
                outOfStock: outOfStockProducts
            },
            customers: {
                total: totalCustomers,
                repeat: repeatCustomers,
                repeatRate: totalCustomers > 0 ? ((repeatCustomers / totalCustomers) * 100).toFixed(1) : 0
            },
            period: {
                startDate: rangeStart,
                endDate: rangeEnd,
                previousStartDate: previousRangeStart,
                previousEndDate: previousRangeEnd
            }
        });
    } catch (error) {
        console.error('Dashboard analytics error:', error);
        res.status(error.statusCode || 500).json({ message: error.message });
    }
});

// @route   GET /api/analytics/revenue-chart
// @desc    Get monthly revenue data for chart
// @access  Private
router.get('/revenue-chart', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { rangeStart, rangeEnd, hasCustomRange, anchorMonth } = getDateFilter(req.query);
        let chartStart;
        let chartEnd;

        if (hasCustomRange) {
            chartStart = new Date(rangeStart.getFullYear(), rangeStart.getMonth(), 1);
            chartEnd = new Date(rangeEnd.getFullYear(), rangeEnd.getMonth() + 1, 0, 23, 59, 59, 999);
        } else {
            chartStart = new Date(anchorMonth.getFullYear(), anchorMonth.getMonth() - 5, 1);
            chartEnd = new Date(anchorMonth.getFullYear(), anchorMonth.getMonth() + 1, 0, 23, 59, 59, 999);
        }

        const [revenueAgg, expenseAgg] = await Promise.all([
            Order.aggregate([
                {
                    $match: {
                        businessId,
                        paymentStatus: 'paid',
                        createdAt: { $gte: chartStart, $lte: chartEnd }
                    }
                },
                {
                    $group: {
                        _id: {
                            year: { $year: '$createdAt' },
                            month: { $month: '$createdAt' }
                        },
                        revenue: { $sum: '$total' },
                        profit: { $sum: '$profit' }
                    }
                },
                { $sort: { '_id.year': 1, '_id.month': 1 } }
            ]),
            Expense.aggregate([
                {
                    $match: {
                        businessId,
                        date: { $gte: chartStart, $lte: chartEnd }
                    }
                },
                {
                    $group: {
                        _id: {
                            year: { $year: '$date' },
                            month: { $month: '$date' }
                        },
                        total: { $sum: '$amount' }
                    }
                },
                { $sort: { '_id.year': 1, '_id.month': 1 } }
            ])
        ]);

        const revenueMap = new Map(
            revenueAgg.map((row) => [
                toMonthKey(row._id.year, row._id.month),
                { revenue: row.revenue || 0, profit: row.profit || 0 }
            ])
        );
        const expenseMap = new Map(
            expenseAgg.map((row) => [
                toMonthKey(row._id.year, row._id.month),
                row.total || 0
            ])
        );

        const data = [];
        let iter = new Date(chartStart.getFullYear(), chartStart.getMonth(), 1);
        while (iter <= chartEnd) {
            const year = iter.getFullYear();
            const month = iter.getMonth() + 1;
            const key = toMonthKey(year, month);
            const revenueRow = revenueMap.get(key) || { revenue: 0, profit: 0 };
            data.push({
                month: monthLabel(year, month),
                revenue: revenueRow.revenue,
                profit: revenueRow.profit,
                expenses: expenseMap.get(key) || 0
            });
            iter = new Date(iter.getFullYear(), iter.getMonth() + 1, 1);
        }

        res.json(data);
    } catch (error) {
        res.status(error.statusCode || 500).json({ message: error.message });
    }
});

// @route   GET /api/analytics/top-products
// @desc    Get top selling products
// @access  Private
router.get('/top-products', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { rangeStart, rangeEnd } = getDateFilter(req.query);

        const result = await Order.aggregate([
            {
                $match: {
                    businessId,
                    status: { $ne: 'cancelled' },
                    createdAt: { $gte: rangeStart, $lte: rangeEnd }
                }
            },
            { $unwind: '$items' },
            {
                $group: {
                    _id: '$items.productId',
                    name: { $first: '$items.name' },
                    totalQuantity: { $sum: '$items.quantity' },
                    totalRevenue: { $sum: '$items.total' }
                }
            },
            { $sort: { totalQuantity: -1 } },
            { $limit: 5 }
        ]);

        res.json(result);
    } catch (error) {
        res.status(error.statusCode || 500).json({ message: error.message });
    }
});

// @route   GET /api/analytics/health-score
// @desc    Calculate business health score
// @access  Private
router.get('/health-score', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { rangeStart, rangeEnd } = getDateFilter(req.query);
        const rangeDays = Math.max(
            1,
            Math.ceil((rangeEnd.getTime() - rangeStart.getTime() + 1) / (24 * 60 * 60 * 1000))
        );

        // Factor 1: Order frequency (max 25 points)
        const recentOrders = await Order.countDocuments({
            businessId,
            status: { $ne: 'cancelled' },
            createdAt: { $gte: rangeStart, $lte: rangeEnd }
        });
        const targetOrders = Math.max(10, Math.round(rangeDays / 3));
        const orderScore = Math.min(25, (recentOrders / targetOrders) * 25);

        // Factor 2: Profit margin (max 25 points)
        const profitResult = await Order.aggregate([
            { $match: { businessId, paymentStatus: 'paid', createdAt: { $gte: rangeStart, $lte: rangeEnd } } },
            { $group: { _id: null, revenue: { $sum: '$total' }, profit: { $sum: '$profit' } } }
        ]);
        const revenue = profitResult[0]?.revenue || 0;
        const profit = profitResult[0]?.profit || 0;
        const profitMargin = revenue > 0 ? (profit / revenue) * 100 : 0;
        const marginScore = Math.min(25, profitMargin);

        // Factor 3: Inventory health (max 25 points)
        const totalProducts = await Product.countDocuments({ businessId, isActive: true });
        const healthyStock = await Product.countDocuments({ businessId, isActive: true, stock: { $gt: 5 } });
        const inventoryHealth = totalProducts > 0 ? (healthyStock / totalProducts) * 100 : 100;
        const inventoryScore = (inventoryHealth / 100) * 25;

        // Factor 4: Repeat customers (max 25 points)
        const totalCustomers = await Customer.countDocuments({ businessId });
        const repeatCustomers = await Customer.countDocuments({ businessId, isRepeatCustomer: true });
        const repeatRate = totalCustomers > 0 ? (repeatCustomers / totalCustomers) * 100 : 0;
        const repeatScore = (repeatRate / 100) * 25;

        const totalScore = Math.round(orderScore + marginScore + inventoryScore + repeatScore);

        // Generate tips based on weakest areas
        const tips = [];
        if (orderScore < 15) tips.push('Increase marketing to get more orders');
        if (marginScore < 15) tips.push('Review pricing to improve profit margins');
        if (inventoryScore < 15) tips.push('Restock products running low on inventory');
        if (repeatScore < 15) tips.push('Focus on customer retention for repeat business');
        if (tips.length === 0) tips.push('Great job! Keep up the good work!');

        res.json({
            score: totalScore,
            breakdown: {
                orderFrequency: Math.round(orderScore),
                profitMargin: Math.round(marginScore),
                inventoryHealth: Math.round(inventoryScore),
                customerRetention: Math.round(repeatScore)
            },
            tips: tips.slice(0, 3),
            status: totalScore >= 70 ? 'healthy' : totalScore >= 40 ? 'moderate' : 'needs_attention'
        });
    } catch (error) {
        res.status(error.statusCode || 500).json({ message: error.message });
    }
});

module.exports = router;
