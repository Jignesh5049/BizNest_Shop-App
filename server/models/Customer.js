const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema({
    businessId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Business',
        required: true
    },
    name: {
        type: String,
        required: [true, 'Customer name is required'],
        trim: true,
        maxlength: [100, 'Name cannot exceed 100 characters']
    },
    phone: {
        type: String,
        trim: true
    },
    email: {
        type: String,
        trim: true,
        lowercase: true
    },
    address: {
        street: String,
        city: String,
        state: String,
        pincode: String
    },
    notes: {
        type: String,
        trim: true,
        maxlength: [500, 'Notes cannot exceed 500 characters']
    },
    orderCount: {
        type: Number,
        default: 0
    },
    totalSpent: {
        type: Number,
        default: 0
    },
    lastOrderDate: {
        type: Date
    },
    isRepeatCustomer: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

customerSchema.pre('save', function (next) {
    this.updatedAt = Date.now();
    // Mark as repeat customer if they have more than 1 order
    this.isRepeatCustomer = this.orderCount > 1;
    next();
});

customerSchema.index({ businessId: 1 });
customerSchema.index({ businessId: 1, name: 'text' });

module.exports = mongoose.model('Customer', customerSchema);
