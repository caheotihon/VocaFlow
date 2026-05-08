const mongoose = require('mongoose');

const connectDB = async () => {
  const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/lingopro';
  await mongoose.connect(uri);
  console.log('✅ MongoDB connected:', uri);
};

module.exports = connectDB;
