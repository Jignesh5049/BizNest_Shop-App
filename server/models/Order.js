const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
    productId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: true
    },
    name: {
        type: String,
        required: true
    },
    quantity: {
        type: Number,
        required: true,
        min: [1, 'Quantity must be at least 1']
    },
    price: {
        type: Number,
        required: true
    },
    image: {
        type: String,
        default: ''
    },
    costPrice: {
        type: Number,
        required: true
    },
    total: {
        type: Number,
        required: true
    }
});

const orderSchema = new mongoose.Schema({
    businessId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Business',
        required: true
    },
    customerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Customer',
        required: true
    },
    customerUserId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    orderNumber: {
        type: String
    },
    items: [orderItemSchema],
    subtotal: {
        type: Number,
        required: true,
        default: 0
    },
    discount: {
        type: Number,
        default: 0
    },
    tax: {
        type: Number,
        default: 0
    },
    total: {
        type: Number,
        required: true,
        default: 0
    },
    totalCost: {
        type: Number,
        required: true,
        default: 0
    },
    profit: {
        type: Number,
        default: 0
    },
    status: {
        type: String,
        enum: ['pending', 'confirmed', 'completed', 'cancelled'],
        default: 'pending'
    },
    paymentStatus: {
        type: String,
        enum: ['unpaid', 'partial', 'paid'],
        default: 'unpaid'
    },
    paymentMethod: {
        type: String,
        enum: ['cash', 'upi', 'card', 'bank', 'other'],
        default: 'cash'
    },
    notes: {
        type: String,
        trim: true,
        maxlength: [500, 'Notes cannot exceed 500 characters']
    },
    deliveryAddress: {
        street: String,
        city: String,
        state: String,
        pincode: String
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    },
    paidAt: {
        type: Date
    }
});

// Generate order number before saving
orderSchema.pre('save', async function (next) {
    this.updatedAt = Date.now();

    if (this.isNew) {
        const count = await mongoose.model('Order').countDocuments({ businessId: this.businessId });
        this.orderNumber = `ORD-${String(count + 1).padStart(5, '0')}`;
    }

    // Calculate profit
    this.profit = this.total - this.totalCost - this.discount;

    next();
});

orderSchema.index({ businessId: 1, createdAt: -1 });
orderSchema.index({ businessId: 1, customerId: 1 });
orderSchema.index({ businessId: 1, status: 1 });

module.exports = mongoose.model('Order', orderSchema);
