const mongoose = require('mongoose');

/**
 * Favorite Model — user's saved/favorited words
 */
const favoriteSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    word: { type: mongoose.Schema.Types.ObjectId, ref: 'Word', required: true },
    note: { type: String, default: '' }, // optional personal note
  },
  { timestamps: true }
);

favoriteSchema.index({ user: 1, word: 1 }, { unique: true });

module.exports = mongoose.model('Favorite', favoriteSchema);
