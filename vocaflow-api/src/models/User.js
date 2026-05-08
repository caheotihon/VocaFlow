const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

/**
 * User Model
 * Supports both local JWT auth and Google OAuth
 */
const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, select: false }, // null for Google users
    avatar: { type: String, default: null },

    // Google OAuth
    googleId: { type: String, default: null },
    authProvider: { type: String, enum: ['local', 'google'], default: 'local' },

    // Streak & gamification
    streakDays: { type: Number, default: 0 },
    lastActiveDate: { type: Date, default: null },
    totalXP: { type: Number, default: 0 },
    dailyXP: { type: Number, default: 0 },
    dailyGoal: { type: Number, default: 20 }, // words per day
    goalAccuracy: { type: Number, default: 80 }, // target accuracy %

    // Badges earned
    badges: [{ type: String }],

    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

// Hash password before save
userSchema.pre('save', async function (next) {
  if (!this.isModified('password') || !this.password) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

// Compare password
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Update streak logic
userSchema.methods.updateStreak = function () {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  if (!this.lastActiveDate) {
    this.streakDays = 1;
  } else {
    const last = new Date(this.lastActiveDate);
    last.setHours(0, 0, 0, 0);
    const diffDays = Math.floor((today - last) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return; // already updated today
    if (diffDays === 1) this.streakDays += 1;
    else this.streakDays = 1; // streak broken
  }

  this.lastActiveDate = new Date();
};

module.exports = mongoose.model('User', userSchema);
