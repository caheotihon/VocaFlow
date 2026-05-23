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

    // Profile extras
    bio: { type: String, default: '', trim: true },

    // Google OAuth
    googleId: { type: String, default: null },
    authProvider: { type: String, enum: ['local', 'google'], default: 'local' },

    // Streak & gamification
    streakDays: { type: Number, default: 0 },
    bestStreak: { type: Number, default: 0 }, // highest streak ever
    lastActiveDate: { type: Date, default: null },
    totalXP: { type: Number, default: 0 },
    dailyXP: { type: Number, default: 0 },
    dailyGoal: { type: Number, default: 20 }, // words per day
    goalAccuracy: { type: Number, default: 80 }, // target accuracy %

    // Daily Progress / Words Learned Flow
    wordsLearnedToday: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Word' }],
    dailyGoalClaimed: { type: Boolean, default: false },
    lastWordsResetDate: { type: String, default: '' },

    // Streak milestone rewards already given (avoid duplicates)
    streakMilestonesClaimed: [{ type: Number }],

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

// Update streak logic — returns { streakBroken, milestoneReached }
userSchema.methods.updateStreak = function () {
  const toUTCMidnight = (d) => {
    const x = new Date(d);
    x.setUTCHours(0, 0, 0, 0);
    return x;
  };

  const today = toUTCMidnight(new Date());

  let streakBroken = false;

  if (!this.lastActiveDate) {
    this.streakDays = 1;
  } else {
    const last = toUTCMidnight(this.lastActiveDate);
    const diffDays = Math.floor((today - last) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return { streakBroken: false, milestoneReached: null }; // already updated today
    if (diffDays === 1) {
      this.streakDays += 1;
    } else {
      this.streakDays = 1; // streak broken
      streakBroken = true;
    }
  }

  // Track best streak
  if (this.streakDays > this.bestStreak) {
    this.bestStreak = this.streakDays;
  }

  this.lastActiveDate = new Date();

  // Check milestones (7, 30, 100 days)
  const milestones = [7, 30, 100];
  let milestoneReached = null;
  for (const milestone of milestones) {
    if (this.streakDays >= milestone && !this.streakMilestonesClaimed.includes(milestone)) {
      this.streakMilestonesClaimed.push(milestone);
      const bonusXP = milestone === 7 ? 100 : milestone === 30 ? 500 : 2000;
      this.totalXP += bonusXP;
      this.dailyXP += bonusXP;
      milestoneReached = { days: milestone, bonusXP };

      // Award badge
      const badgeName = `${milestone}-Day Streak`;
      if (!this.badges.includes(badgeName)) {
        this.badges.push(badgeName);
      }
    }
  }

  return { streakBroken, milestoneReached };
};

// Get streak to display for "today" (0 if streak is already broken)
userSchema.methods.getStreakForToday = function () {
  if (!this.lastActiveDate) return 0;

  const toUTCMidnight = (d) => {
    const x = new Date(d);
    x.setUTCHours(0, 0, 0, 0);
    return x;
  };

  const today = toUTCMidnight(new Date());
  const last = toUTCMidnight(this.lastActiveDate);
  const diffDays = Math.floor((today - last) / (1000 * 60 * 60 * 24));

  if (diffDays > 1) return 0;
  return this.streakDays || 0;
};

module.exports = mongoose.model('User', userSchema);
