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
 * Supports both id_token (Firebase) and access_token paths
 */
exports.googleLogin = async (req, res) => {
  try {
    const { idToken, accessToken, email, name, avatar, googleId } = req.body;

    // Path 1: Direct profile data (from google_sign_in without Firebase)
    if (!idToken && email && name) {
      let user = await User.findOne({ $or: [{ googleId }, { email }] });
      if (!user) {
        user = await User.create({
          name, email,
          googleId: googleId || null,
          avatar: avatar || null,
          authProvider: 'google',
        });
      } else {
        if (!user.googleId && googleId) user.googleId = googleId;
        user.authProvider = 'google';
        if (!user.avatar && avatar) user.avatar = avatar;
      }
      user.updateStreak();
      await user.save();
      const token = generateToken(user._id);
      return successResponse(res, { token, user: _safeUser(user) }, 'Google login successful');
    }

    // Path 2: ID token verification (Firebase / standard OAuth)
    if (!idToken) return errorResponse(res, 'Google credentials required', 400);

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { sub: gId, email: gEmail, name: gName, picture } = payload;

    let user = await User.findOne({ $or: [{ googleId: gId }, { email: gEmail }] });
    if (!user) {
      user = await User.create({
        name: gName, email: gEmail, googleId: gId, avatar: picture,
        authProvider: 'google',
      });
    } else if (!user.googleId) {
      user.googleId = gId;
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
 * Update user profile — name, bio, dailyGoal, goalAccuracy, avatar (URL)
 */
exports.updateProfile = async (req, res) => {
  try {
    const { name, bio, dailyGoal, goalAccuracy, avatar } = req.body;
    const updates = {};
    if (name !== undefined) updates.name = name;
    if (bio !== undefined) updates.bio = bio;
    if (dailyGoal !== undefined) updates.dailyGoal = Number(dailyGoal);
    if (goalAccuracy !== undefined) updates.goalAccuracy = Number(goalAccuracy);
    if (avatar !== undefined) updates.avatar = avatar;

    const user = await User.findByIdAndUpdate(req.user._id, updates, { new: true });
    return successResponse(res, { user: _safeUser(user) }, 'Profile updated');
  } catch (err) {
    console.error('[Auth/profile]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};

/** Strip sensitive fields */
const _safeUser = (user) => ({
  _id: user._id,
  name: user.name,
  email: user.email,
  avatar: user.avatar,
  bio: user.bio || '',
  streakDays: user.streakDays,
  bestStreak: user.bestStreak || 0,
  totalXP: user.totalXP,
  dailyXP: user.dailyXP,
  dailyGoal: user.dailyGoal,
  goalAccuracy: user.goalAccuracy,
  badges: user.badges,
  streakMilestonesClaimed: user.streakMilestonesClaimed || [],
  authProvider: user.authProvider,
  createdAt: user.createdAt,
});
