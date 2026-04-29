const mongoose = require('mongoose');

const supportTicketSchema = new mongoose.Schema({
    businessId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Business'
    },
    orderId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Order'
    },
    productId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product'
    },
    customerUserId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    customerName: {
        type: String,
        required: true,
        trim: true,
        maxlength: [100, 'Customer name cannot exceed 100 characters']
    },
    customerEmail: {
        type: String,
        required: true,
        trim: true,
        lowercase: true
    },
    type: {
        type: String,
        enum: ['support', 'feedback'],
        default: 'support'
    },
    issueType: {
        type: String,
        enum: ['complaint', 'return', 'replace', 'damaged', 'wrong_item', 'other'],
        default: 'complaint'
    },
    subject: {
        type: String,
        trim: true,
        maxlength: [200, 'Subject cannot exceed 200 characters']
    },
    message: {
        type: String,
        required: [true, 'Message is required'],
        trim: true,
        maxlength: [2000, 'Message cannot exceed 2000 characters']
    },
    status: {
        type: String,
        enum: ['open', 'in_progress', 'resolved'],
        default: 'open'
    },
    replyMessage: {
        type: String,
        trim: true,
        maxlength: [2000, 'Reply cannot exceed 2000 characters']
    },
    repliedAt: {
        type: Date
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

supportTicketSchema.pre('save', function (next) {
    this.updatedAt = Date.now();
    next();
});

supportTicketSchema.index({ businessId: 1, createdAt: -1 });
supportTicketSchema.index({ customerUserId: 1, createdAt: -1 });

module.exports = mongoose.model('SupportTicket', supportTicketSchema);
