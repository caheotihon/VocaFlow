const User = require('../models/User');
const { generateToken, successResponse, errorResponse } = require('../utils/helpers');
const { OAuth2Client } = require('google-auth-library');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

/**
 * POST /api/auth/register
 * Register a new user with email + password
 */
exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password)
      return errorResponse(res, 'Name, email and password are required', 400);

    const exists = await User.findOne({ email });
    if (exists) return errorResponse(res, 'Email already registered', 409);

    const user = await User.create({ name, email, password, authProvider: 'local' });
    const token = generateToken(user._id);

    return successResponse(res, { token, user: _safeUser(user) }, 'Registered successfully', 201);
  } catch (err) {
    console.error('[Auth/register]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * POST /api/auth/login
 * Login with email + password
 */
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return errorResponse(res, 'Email and password are required', 400);

    const user = await User.findOne({ email }).select('+password');
    if (!user || !(await user.comparePassword(password)))
      return errorResponse(res, 'Invalid credentials', 401);

    user.updateStreak();
    await user.save();

    const token = generateToken(user._id);
    return successResponse(res, { token, user: _safeUser(user) }, 'Login successful');
  } catch (err) {
    console.error('[Auth/login]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * POST /api/auth/google
 * Google OAuth login — validate idToken from Flutter
 */
exports.googleLogin = async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) return errorResponse(res, 'Google ID token required', 400);

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { sub: googleId, email, name, picture } = payload;

    let user = await User.findOne({ $or: [{ googleId }, { email }] });
    if (!user) {
      user = await User.create({
        name, email, googleId, avatar: picture,
        authProvider: 'google',
      });
    } else if (!user.googleId) {
      user.googleId = googleId;
      user.authProvider = 'google';
      if (!user.avatar) user.avatar = picture;
    }

    user.updateStreak();
    await user.save();

    const token = generateToken(user._id);
    return successResponse(res, { token, user: _safeUser(user) }, 'Google login successful');
  } catch (err) {
    console.error('[Auth/google]', err.message);
    return errorResponse(res, 'Google authentication failed', 401);
  }
};

/**
 * GET /api/auth/me
 * Get current user profile
 */
exports.getMe = async (req, res) => {
  return successResponse(res, { user: _safeUser(req.user) });
};

/**
 * PUT /api/auth/profile
 * Update user profile
 */
exports.updateProfile = async (req, res) => {
  try {
    const { name, dailyGoal, goalAccuracy } = req.body;
    const updates = {};
    if (name) updates.name = name;
    if (dailyGoal) updates.dailyGoal = dailyGoal;
    if (goalAccuracy) updates.goalAccuracy = goalAccuracy;

    const user = await User.findByIdAndUpdate(req.user._id, updates, { new: true });
    return successResponse(res, { user: _safeUser(user) }, 'Profile updated');
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/** Strip sensitive fields */
const _safeUser = (user) => ({
  _id: user._id,
  name: user.name,
  email: user.email,
  avatar: user.avatar,
  streakDays: user.streakDays,
  totalXP: user.totalXP,
  dailyXP: user.dailyXP,
  dailyGoal: user.dailyGoal,
  goalAccuracy: user.goalAccuracy,
  badges: user.badges,
  authProvider: user.authProvider,
  createdAt: user.createdAt,
});
