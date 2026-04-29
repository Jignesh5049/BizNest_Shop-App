/**
 * Sample Data Seeder for BizNest
 * Run: node seed.js
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const User = require('./models/User');
const Business = require('./models/Business');
const Product = require('./models/Product');
const Customer = require('./models/Customer');
const Order = require('./models/Order');
const Expense = require('./models/Expense');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/biznest';

const seedData = async () => {
    try {
        await mongoose.connect(MONGODB_URI);
        console.log('Connected to MongoDB');

        // Clear existing data
        await Promise.all([
            User.deleteMany({}),
            Business.deleteMany({}),
            Product.deleteMany({}),
            Customer.deleteMany({}),
            Order.deleteMany({}),
            Expense.deleteMany({})
        ]);
        console.log('Cleared existing data');

        // Create demo user
        const user = await User.create({
            name: 'Demo User',
            email: 'demo@biznest.com',
            password: 'demo123'
        });
        console.log('Created demo user: demo@biznest.com / demo123');

        // Create business
        const business = await Business.create({
            userId: user._id,
            name: 'Artisan Crafts Store',
            category: 'handmade',
            description: 'Beautiful handcrafted items made with love',
            contact: {
                phone: '+91 98765 43210',
                email: 'contact@artisancrafts.com',
                whatsapp: '+91 98765 43210'
            },
            address: {
                city: 'Mumbai',
                state: 'Maharashtra'
            },
            isOnboarded: true
        });
        console.log('Created business profile');

        // Create products
        const products = await Product.insertMany([
            {
                businessId: business._id,
                name: 'Handwoven Cotton Bag',
                description: 'Eco-friendly handwoven bag made from organic cotton',
                costPrice: 200,
                sellingPrice: 450,
                stock: 25,
                unit: 'piece',
                category: 'Bags'
            },
            {
                businessId: business._id,
                name: 'Ceramic Tea Cup Set',
                description: 'Set of 4 hand-painted ceramic cups',
                costPrice: 350,
                sellingPrice: 750,
                stock: 15,
                unit: 'box',
                category: 'Kitchenware'
            },
            {
                businessId: business._id,
                name: 'Wooden Photo Frame',
                description: 'Handcarved wooden frame - 8x10 inches',
                costPrice: 150,
                sellingPrice: 350,
                stock: 30,
                unit: 'piece',
                category: 'Decor'
            },
            {
                businessId: business._id,
                name: 'Embroidered Cushion Cover',
                description: 'Traditional embroidery on cotton fabric',
                costPrice: 180,
                sellingPrice: 400,
                stock: 20,
                unit: 'piece',
                category: 'Home Decor'
            },
            {
                businessId: business._id,
                name: 'Handmade Soap Set',
                description: 'Pack of 3 natural ingredient soaps',
                costPrice: 100,
                sellingPrice: 250,
                stock: 50,
                unit: 'pack',
                category: 'Bath & Body'
            }
        ]);
        console.log(`Created ${products.length} products`);

        // Create customers
        const customers = await Customer.insertMany([
            {
                businessId: business._id,
                name: 'Priya Sharma',
                phone: '+91 99876 54321',
                email: 'priya.sharma@email.com',
                address: { city: 'Mumbai', state: 'Maharashtra' }
            },
            {
                businessId: business._id,
                name: 'Rahul Verma',
                phone: '+91 98765 12345',
                email: 'rahul.v@email.com',
                address: { city: 'Pune', state: 'Maharashtra' }
            },
            {
                businessId: business._id,
                name: 'Anita Patel',
                phone: '+91 97654 32109',
                email: 'anita.patel@email.com',
                address: { city: 'Ahmedabad', state: 'Gujarat' }
            }
        ]);
        console.log(`Created ${customers.length} customers`);

        // Create some orders
        const orders = [];

        // Order 1 - Paid, Completed
        const order1 = await Order.create({
            businessId: business._id,
            customerId: customers[0]._id,
            items: [
                { productId: products[0]._id, name: products[0].name, quantity: 2, price: products[0].sellingPrice, costPrice: products[0].costPrice, total: products[0].sellingPrice * 2 },
                { productId: products[2]._id, name: products[2].name, quantity: 1, price: products[2].sellingPrice, costPrice: products[2].costPrice, total: products[2].sellingPrice }
            ],
            subtotal: 1250,
            total: 1250,
            totalCost: 550,
            profit: 700,
            status: 'completed',
            paymentStatus: 'paid',
            paymentMethod: 'upi',
            paidAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
        });
        orders.push(order1);

        // Order 2 - Paid
        const order2 = await Order.create({
            businessId: business._id,
            customerId: customers[1]._id,
            items: [
                { productId: products[1]._id, name: products[1].name, quantity: 1, price: products[1].sellingPrice, costPrice: products[1].costPrice, total: products[1].sellingPrice }
            ],
            subtotal: 750,
            total: 750,
            totalCost: 350,
            profit: 400,
            status: 'confirmed',
            paymentStatus: 'paid',
            paymentMethod: 'cash',
            paidAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
        });
        orders.push(order2);

        // Order 3 - Pending
        const order3 = await Order.create({
            businessId: business._id,
            customerId: customers[2]._id,
            items: [
                { productId: products[3]._id, name: products[3].name, quantity: 3, price: products[3].sellingPrice, costPrice: products[3].costPrice, total: products[3].sellingPrice * 3 },
                { productId: products[4]._id, name: products[4].name, quantity: 2, price: products[4].sellingPrice, costPrice: products[4].costPrice, total: products[4].sellingPrice * 2 }
            ],
            subtotal: 1700,
            total: 1700,
            totalCost: 740,
            profit: 960,
            status: 'pending',
            paymentStatus: 'unpaid',
            paymentMethod: 'cash'
        });
        orders.push(order3);

        console.log(`Created ${orders.length} orders`);

        // Update customer stats
        await Customer.findByIdAndUpdate(customers[0]._id, {
            orderCount: 1,
            totalSpent: 1250,
            lastOrderDate: new Date()
        });
        await Customer.findByIdAndUpdate(customers[1]._id, {
            orderCount: 1,
            totalSpent: 750,
            lastOrderDate: new Date()
        });

        // Create expenses
        const expenses = await Expense.insertMany([
            {
                businessId: business._id,
                category: 'raw_material',
                amount: 5000,
                description: 'Cotton fabric bulk purchase',
                date: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000)
            },
            {
                businessId: business._id,
                category: 'packaging',
                amount: 800,
                description: 'Gift boxes and packaging materials',
                date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000)
            },
            {
                businessId: business._id,
                category: 'marketing',
                amount: 500,
                description: 'Instagram promotion',
                date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
            },
            {
                businessId: business._id,
                category: 'delivery',
                amount: 300,
                description: 'Courier charges',
                date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000)
            }
        ]);
        console.log(`Created ${expenses.length} expenses`);

        console.log('\n✅ Seed data created successfully!');
        console.log('\n📧 Demo Login:');
        console.log('   Email: demo@biznest.com');
        console.log('   Password: demo123\n');

        process.exit(0);
    } catch (error) {
        console.error('Error seeding data:', error);
        process.exit(1);
    }
};

seedData();
