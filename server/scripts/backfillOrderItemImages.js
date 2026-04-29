/*
 * One-time migration: backfill product images into existing order items.
 * Run: node scripts/backfillOrderItemImages.js
 */

const mongoose = require('mongoose');
require('dotenv').config();

const Order = require('../models/Order');
const Product = require('../models/Product');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/biznest';

const isMissingImage = (value) => value === undefined || value === null || value === '';

const backfillOrderItemImages = async () => {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    const orders = await Order.find({
        $or: [
            { 'items.image': { $exists: false } },
            { 'items.image': '' },
            { 'items.image': null }
        ]
    }).select('items');

    if (!orders.length) {
        console.log('No orders found that require backfill.');
        return;
    }

    const productIds = new Set();
    orders.forEach(order => {
        order.items?.forEach(item => {
            if (isMissingImage(item.image) && item.productId) {
                productIds.add(item.productId.toString());
            }
        });
    });

    if (!productIds.size) {
        console.log('No order items with missing images found.');
        return;
    }

    const products = await Product.find({ _id: { $in: Array.from(productIds) } })
        .select('_id image');
    const imageMap = new Map(products.map(product => [product._id.toString(), product.image]));

    let updatedOrders = 0;
    let updatedItems = 0;
    let missingProducts = 0;

    const updates = orders.reduce((acc, order) => {
        const orderObj = order.toObject();
        let hasChanges = false;

        const updatedItemsList = orderObj.items.map(item => {
            if (!isMissingImage(item.image)) {
                return item;
            }

            const image = imageMap.get(item.productId?.toString()) || '';
            if (image) {
                hasChanges = true;
                updatedItems += 1;
                return { ...item, image };
            }

            missingProducts += 1;
            return item;
        });

        if (hasChanges) {
            updatedOrders += 1;
            acc.push({
                updateOne: {
                    filter: { _id: order._id },
                    update: { $set: { items: updatedItemsList } }
                }
            });
        }

        return acc;
    }, []);

    if (!updates.length) {
        console.log('No updates applied.');
        return;
    }

    const result = await Order.bulkWrite(updates);

    console.log('Backfill complete.');
    console.log(`Orders scanned: ${orders.length}`);
    console.log(`Orders updated: ${updatedOrders}`);
    console.log(`Items updated: ${updatedItems}`);
    console.log(`Items missing products: ${missingProducts}`);
    console.log(`Matched: ${result.matchedCount}, Modified: ${result.modifiedCount}`);
};

backfillOrderItemImages()
    .then(() => process.exit(0))
    .catch(error => {
        console.error('Backfill failed:', error);
        process.exit(1);
    });
