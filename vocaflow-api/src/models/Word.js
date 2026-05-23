const mongoose = require('mongoose');

/**
 * Word Model — Core vocabulary data
 */
const wordSchema = new mongoose.Schema(
  {
    word: { type: String, required: true, trim: true, lowercase: true, index: true },
    meaning_vn: { type: String, required: true },
    definition_vn: { type: String, default: '' },
    definition_en: { type: String, default: '' },
    example: { type: String, default: '' },
    example_vn: { type: String, default: '' },
    pronunciation: { type: String, default: '' },
    audio_url: { type: String, default: '' },
    image_url: { type: String, default: '' },

    // Classification
    level: { type: String, enum: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'], required: true, index: true },
    source: {
      type: String,
      enum: ['Oxford 5000', 'Oxford 3000', 'Cambridge B1/B2', 'IELTS Core', 'TOEIC Core', 'AI Generated'],
      required: true,
      index: true,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    topic: { type: String, required: true, index: true },
    difficulty: { type: Number, min: 1, max: 5, default: 1 },
    frequency_rank: { type: Number, default: 9999 },
    tags: [{ type: String }],

    // Part of speech
    partOfSpeech: { type: String, default: 'noun' },

    // Synonyms / antonyms for richer learning
    synonyms: [{ type: String }],
    antonyms: [{ type: String }],
  },
  { timestamps: true }
);

// Text search index
wordSchema.index({ word: 'text', meaning_vn: 'text', definition_vn: 'text' });

module.exports = mongoose.model('Word', wordSchema);
