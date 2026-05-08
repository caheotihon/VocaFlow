/**
 * LingoPro — Database Seeder
 * Chạy: node seedData.js
 */
require('dotenv').config();
const mongoose = require('mongoose');
const Word = require('../models/Word'); // Đảm bảo đường dẫn tới Model đúng
// Đổi từ require file .js sang file .json vừa tạo ra
const words = require('./words_final.json');

const seed = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/lingopro');
    console.log('✅ Connected to MongoDB');

    let updatedCount = 0;

    for (const item of words) {
      // Dùng updateOne để chỉ cập nhật audio_url nếu từ đã tồn tại
      // upsert: true sẽ tự tạo mới nếu từ đó chưa có trong DB
      await Word.updateOne(
        { word: item.word },
        { $set: item },
        { upsert: true }
      );
      updatedCount++;
    }

    console.log(`🌱 Done! Processed ${updatedCount} words.`);
    process.exit(0);
  } catch (err) {
    console.error('❌ Failed:', err.message);
    process.exit(1);
  }
};

seed();