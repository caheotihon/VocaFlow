const mongoose = require('mongoose');

/**
 * Story Model — stores AI-generated stories and associated reading quizzes
 */
const storySchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    content: {
      type: String,
      required: true,
    },
    translation: {
      type: String,
      default: '',
    },
    words: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Word',
        required: true,
      },
    ],
    quiz: [
      {
        question: { type: String, required: true },
        options: [{ type: String, required: true }], // 4 multiple choice options
        answerIndex: { type: Number, required: true, min: 0, max: 3 }, // 0-3 index
        explanation: { type: String, default: '' }, // explanation in Vietnamese
      },
    ],
    isCompleted: {
      type: Boolean,
      default: false,
    },
    xpEarned: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Story', storySchema);
