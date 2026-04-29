const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema({
    businessId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Business',
        required: true
    },
    category: {
        type: String,
        required: [true, 'Expense category is required'],
        enum: ['raw_material', 'delivery', 'marketing', 'utilities', 'rent', 'salary', 'equipment', 'packaging', 'misc']
    },
    amount: {
        type: Number,
        required: [true, 'Amount is required'],
        min: [0, 'Amount cannot be negative']
    },
    description: {
        type: String,
        trim: true,
        maxlength: [500, 'Description cannot exceed 500 characters']
    },
    date: {
        type: Date,
        default: Date.now
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

expenseSchema.index({ businessId: 1, date: -1 });
expenseSchema.index({ businessId: 1, category: 1 });

module.exports = mongoose.model('Expense', expenseSchema);
