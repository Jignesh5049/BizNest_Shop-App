const mongoose = require('mongoose');

const businessSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true
    },
    name: {
        type: String,
        required: [true, 'Business name is required'],
        trim: true,
        maxlength: [200, 'Business name cannot exceed 200 characters']
    },
    category: {
        type: String,
        required: [true, 'Business category is required'],
        enum: ['retail', 'food', 'services', 'handmade', 'consulting', 'other']
    },
    description: {
        type: String,
        trim: true,
        maxlength: [500, 'Description cannot exceed 500 characters']
    },
    contact: {
        phone: {
            type: String,
            trim: true
        },
        email: {
            type: String,
            trim: true,
            lowercase: true
        },
        whatsapp: {
            type: String,
            trim: true
        }
    },
    address: {
        street: String,
        city: String,
        state: String,
        pincode: String
    },
    logo: {
        type: String,
        default: ''
    },
    socialLinks: {
        instagram: String,
        facebook: String,
        website: String
    },
    isOnboarded: {
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

businessSchema.pre('save', function (next) {
    this.updatedAt = Date.now();
    next();
});

module.exports = mongoose.model('Business', businessSchema);
