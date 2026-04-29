const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const Product = require('../models/Product');
const Customer = require('../models/Customer');
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

// @route   GET /api/orders
// @desc    Get all orders
// @access  Private
router.get('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { status, paymentStatus, startDate, endDate, limit = 50 } = req.query;
        const query = { businessId };

        if (status) query.status = status;
        if (paymentStatus) query.paymentStatus = paymentStatus;
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

            query.createdAt = {};
            if (parsedStart) query.createdAt.$gte = parsedStart;
            if (parsedEnd) query.createdAt.$lte = toEndOfDay(parsedEnd);
        }

        const orders = await Order.find(query)
            .populate('customerId', 'name phone email')
            .sort({ createdAt: -1 })
            .limit(parseInt(limit));

        // Backfill missing images from products
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
            const Product = require('../models/Product');
            const products = await Product.find({ _id: { $in: Array.from(productIds) } })
                .select('_id image');
            const imageMap = new Map(products.map(product => [product._id.toString(), product.image]));

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

// @route   GET /api/orders/:id
// @desc    Get single order
// @access  Private
router.get('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const order = await Order.findOne({ _id: req.params.id, businessId })
            .populate('customerId', 'name phone email address');

        if (!order) {
            return res.status(404).json({ message: 'Order not found' });
        }

        res.json(order);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/orders
// @desc    Create order
// @access  Private
router.post('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { customerId, items, discount = 0, tax = 0, notes, deliveryAddress, paymentMethod } = req.body;

        // Calculate totals and update stock
        let subtotal = 0;
        let totalCost = 0;
        const processedItems = [];

        for (const item of items) {
            const product = await Product.findById(item.productId);
            if (!product) {
                return res.status(400).json({ message: `Product not found: ${item.productId}` });
            }

            // Check stock
            if (product.stock < item.quantity) {
                return res.status(400).json({ message: `Insufficient stock for ${product.name}` });
            }

            const itemTotal = product.sellingPrice * item.quantity;
            const itemCost = product.costPrice * item.quantity;

            processedItems.push({
                productId: product._id,
                name: product.name,
                quantity: item.quantity,
                price: product.sellingPrice,
                costPrice: product.costPrice,
                total: itemTotal,
                image: product.image || ''
            });

            subtotal += itemTotal;
            totalCost += itemCost;

            // Stock will be reduced when order is completed, not on creation
        }

        const total = subtotal - discount + tax;

        const order = await Order.create({
            businessId,
            customerId,
            items: processedItems,
            subtotal,
            discount,
            tax,
            total,
            totalCost,
            profit: total - totalCost,
            notes,
            deliveryAddress,
            paymentMethod
        });

        // Update customer stats
        await Customer.findByIdAndUpdate(customerId, {
            $inc: { orderCount: 1, totalSpent: total },
            lastOrderDate: new Date()
        });

        const populatedOrder = await Order.findById(order._id)
            .populate('customerId', 'name phone email');

        res.status(201).json(populatedOrder);
    } catch (error) {
        console.error('Order creation error:', error);
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/orders/:id/status
// @desc    Update order status
// @access  Private
router.put('/:id/status', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const { status } = req.body;

        // Get current order before update
        const currentOrder = await Order.findOne({ _id: req.params.id, businessId });
        if (!currentOrder) {
            return res.status(404).json({ message: 'Order not found' });
        }

        const previousStatus = currentOrder.status;

        // Update order status
        const order = await Order.findOneAndUpdate(
            { _id: req.params.id, businessId },
            { status, updatedAt: Date.now() },
            { new: true }
        ).populate('customerId', 'name phone email');

        // Handle stock updates based on status change
        if (status === 'completed' && previousStatus !== 'completed') {
            // Reduce stock when order is completed
            console.log('Order completed, reducing stock for items:', order.items.length);
            for (const item of order.items) {
                const product = await Product.findById(item.productId);
                if (product) {
                    const oldStock = product.stock;
                    product.stock = Math.max(0, product.stock - item.quantity);
                    await product.save();
                    console.log(`Updated ${product.name}: ${oldStock} -> ${product.stock}`);
                } else {
                    console.warn(`Product not found for item: ${item.productId}`);
                }
            }
        } else if (status === 'cancelled' && previousStatus === 'completed') {
            // Restore stock if order was completed then cancelled
            console.log('Completed order cancelled, restoring stock');
            for (const item of order.items) {
                const product = await Product.findById(item.productId);
                if (product) {
                    const oldStock = product.stock;
                    product.stock += item.quantity;
                    await product.save();
                    console.log(`Restored ${product.name}: ${oldStock} -> ${product.stock}`);
                }
            }
        }

        res.json(order);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/orders/:id/payment
// @desc    Update payment status
// @access  Private
router.put('/:id/payment', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const { paymentStatus, paymentMethod } = req.body;

        const updateData = {
            paymentStatus,
            updatedAt: Date.now()
        };

        if (paymentMethod) updateData.paymentMethod = paymentMethod;
        if (paymentStatus === 'paid') updateData.paidAt = new Date();

        const order = await Order.findOneAndUpdate(
            { _id: req.params.id, businessId },
            updateData,
            { new: true }
        ).populate('customerId', 'name phone email');

        if (!order) {
            return res.status(404).json({ message: 'Order not found' });
        }

        res.json(order);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   DELETE /api/orders/:id
// @desc    Cancel order (restore stock if completed)
// @access  Private
router.delete('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const order = await Order.findOne({ _id: req.params.id, businessId });

        if (!order) {
            return res.status(404).json({ message: 'Order not found' });
        }

        // Restore stock only if order was completed (stock was already reduced)
        if (order.status === 'completed') {
            for (const item of order.items) {
                await Product.findByIdAndUpdate(item.productId, {
                    $inc: { stock: item.quantity }
                });
            }
        }

        order.status = 'cancelled';
        await order.save();

        res.json({ message: 'Order cancelled successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
