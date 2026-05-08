const jwt = require('jsonwebtoken');

/**
 * Generate a signed JWT token for a user
 */
const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

/**
 * Standard success response wrapper
 */
const successResponse = (res, data, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({ success: true, message, data });
};

/**
 * Standard error response wrapper
 */
const errorResponse = (res, message = 'Error', statusCode = 400) => {
  return res.status(statusCode).json({ success: false, message });
};

/**
 * Calculate XP earned based on accuracy and words count
 */
const calcXP = (correctAnswers, totalWords) => {
  const baseXP = correctAnswers * 10;
  const bonus = totalWords > 0 && correctAnswers / totalWords >= 0.9 ? 50 : 0;
  return baseXP + bonus;
};

module.exports = { generateToken, successResponse, errorResponse, calcXP };
