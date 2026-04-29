const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
    businessId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Business',
        required: true
    },
    name: {
        type: String,
        required: [true, 'Product name is required'],
        trim: true,
        maxlength: [200, 'Product name cannot exceed 200 characters']
    },
    description: {
        type: String,
        trim: true,
        maxlength: [1000, 'Description cannot exceed 1000 characters']
    },
    category: {
        type: String,
        trim: true
    },
    costPrice: {
        type: Number,
        required: [true, 'Cost price is required'],
        min: [0, 'Cost price cannot be negative']
    },
    sellingPrice: {
        type: Number,
        required: [true, 'Selling price is required'],
        min: [0, 'Selling price cannot be negative']
    },
    stock: {
        type: Number,
        default: 0,
        min: [0, 'Stock cannot be negative']
    },
    unit: {
        type: String,
        default: 'piece',
        enum: ['piece', 'kg', 'g', 'l', 'ml', 'dozen', 'box', 'pack']
    },
    image: {
        type: String,
        default: ''
    },
    ratingAverage: {
        type: Number,
        default: 0
    },
    ratingCount: {
        type: Number,
        default: 0
    },
    isActive: {
        type: Boolean,
        default: true
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

// Virtual for profit per unit
productSchema.virtual('profitPerUnit').get(function () {
    return this.sellingPrice - this.costPrice;
});

// Virtual for profit margin
productSchema.virtual('profitMargin').get(function () {
    if (this.costPrice === 0) return 100;
    return ((this.sellingPrice - this.costPrice) / this.costPrice * 100).toFixed(2);
});

productSchema.pre('save', function (next) {
    this.updatedAt = Date.now();
    next();
});

// Add index for faster queries
productSchema.index({ businessId: 1, isActive: 1 });
productSchema.index({ businessId: 1, name: 'text' });

module.exports = mongoose.model('Product', productSchema);
