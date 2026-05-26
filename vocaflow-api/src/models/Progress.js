const mongoose = require('mongoose');

/**
 * Progress Model — tracks per-user per-word learning status
 * Used for spaced repetition logic
 */
const progressSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    word: { type: mongoose.Schema.Types.ObjectId, ref: 'Word', required: true, index: true },

    // Mastery tracking
    status: {
      type: String,
      enum: ['new', 'learning', 'reviewing', 'mastered'],
      default: 'new',
    },
    mastery: { type: Number, default: 0, min: 0, max: 100 }, // 0-100%

    // Session counters
    times_seen: { type: Number, default: 0 },
    times_correct: { type: Number, default: 0 },
    times_wrong: { type: Number, default: 0 },

    // Spaced Repetition (SM-2 inspired)
    ease_factor: { type: Number, default: 2.5 },
    interval_days: { type: Number, default: 1 },
    last_reviewed: { type: Date, default: null },
    next_review: { type: Date, default: Date.now },

    // XP earned for this word
    xp_earned: { type: Number, default: 0 },
  },
  { timestamps: true }
);

// Compound unique index: one progress record per user per word
progressSchema.index({ user: 1, word: 1 }, { unique: true });

/**
 * Compute next review date using SM-2-like algorithm
 * quality: 0-5 (0=blackout, 5=perfect)
 */
progressSchema.methods.applySpacedRepetition = function (quality) {
  // Clamp quality
  quality = Math.max(0, Math.min(5, quality));

  if (quality < 3) {
    // Failed — reset interval
    this.interval_days = 1;
    this.ease_factor = Math.max(1.3, this.ease_factor - 0.2);
    // Decrease mastery dynamically
    this.mastery = Math.max(0, Math.round(this.mastery * 0.5));
  } else {
    // Passed — increase interval
    if (this.times_seen === 1) {
      this.interval_days = 1;
    } else if (this.interval_days <= 1) {
      this.interval_days = 3;
    } else if (this.interval_days <= 3) {
      this.interval_days = 6;
    } else {
      this.interval_days = Math.round(this.interval_days * this.ease_factor);
    }

    this.ease_factor = this.ease_factor + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
    this.ease_factor = Math.max(1.3, this.ease_factor);
    
    // Increase mastery dynamically (+20% per correct review)
    this.mastery = Math.min(100, this.mastery + 20);
  }

  this.last_reviewed = new Date();
  const nextReview = new Date();
  nextReview.setDate(nextReview.getDate() + this.interval_days);
  this.next_review = nextReview;

  // Update status based on mastery and times seen
  if (this.times_seen === 0) {
    this.status = 'new';
  } else if (this.mastery < 50) {
    this.status = 'learning';
  } else if (this.mastery >= 50 && this.mastery < 85) {
    this.status = 'reviewing';
  } else {
    this.status = 'mastered';
  }
};

module.exports = mongoose.model('Progress', progressSchema);
