const mongoose = require('mongoose');

/**
 * Session Model — records a full practice session
 */
const sessionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },

    // Session configuration
    source: { type: String, required: true },
    level: { type: String },
    topic: { type: String },
    mode: {
      type: String,
      enum: ['flashcard', 'typing', 'listening', 'reverse_recall', 'fill_blank', 'mixed'],
      required: true,
    },

    // Results
    words_studied: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Word' }],
    correct_new_words: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Word' }],
    total_words: { type: Number, default: 0 },
    correct_answers: { type: Number, default: 0 },
    wrong_answers: { type: Number, default: 0 },
    accuracy: { type: Number, default: 0 }, // percentage
    xp_earned: { type: Number, default: 0 },
    duration_seconds: { type: Number, default: 0 },

    // Status
    status: { type: String, enum: ['active', 'completed', 'abandoned'], default: 'active' },
    completed_at: { type: Date, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Session', sessionSchema);
