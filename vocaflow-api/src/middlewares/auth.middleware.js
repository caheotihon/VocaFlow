const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * Middleware: Protect routes — requires valid JWT
 */
const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const user = await User.findById(decoded.id);
    if (!user || !user.isActive) {
      return res.status(401).json({ success: false, message: 'User not found or inactive' });
    }

    // Daily reset check for wordsLearnedToday / dailyGoalClaimed / dailyXP
    const todayStr = new Date().toISOString().split('T')[0];
    if (user.lastWordsResetDate !== todayStr) {
      user.wordsLearnedToday = [];
      user.dailyGoalClaimed = false;
      user.dailyXP = 0;
      user.lastWordsResetDate = todayStr;
      await user.save();
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token' });
  }
};

module.exports = { protect };
