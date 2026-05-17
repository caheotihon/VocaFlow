const Word = require('../models/Word');
const Progress = require('../models/Progress');
const { successResponse, errorResponse } = require('../utils/helpers');

/**
 * GET /api/words
 * Get all words with pagination
 */
exports.getAllWords = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const words = await Word.find().skip(skip).limit(limit).sort({ frequency_rank: 1 });
    const total = await Word.countDocuments();
    return successResponse(res, { words, total, page, pages: Math.ceil(total / limit) });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/words/random
 * Get a random word
 */
exports.getRandomWord = async (req, res) => {
  try {
    const count = await Word.countDocuments();
    const random = Math.floor(Math.random() * count);
    const word = await Word.findOne().skip(random);
    return successResponse(res, { word });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/words/search?q=
 * Full-text search words
 */
exports.searchWords = async (req, res) => {
  try {
    const q = req.query.q || '';
    if (!q) return errorResponse(res, 'Query parameter q is required', 400);

    const words = await Word.find({
      $or: [
        { word: { $regex: q, $options: 'i' } },
        { meaning_vn: { $regex: q, $options: 'i' } },
      ],
    }).limit(30);

    return successResponse(res, { words, total: words.length });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/words/:id
 */
exports.getWordById = async (req, res) => {
  try {
    const word = await Word.findById(req.params.id);
    if (!word) return errorResponse(res, 'Word not found', 404);
    return successResponse(res, { word });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/words/source/:source
 */
exports.getBySource = async (req, res) => {
  try {
    const { source } = req.params;
    const { level, topic, page = 1, limit = 20 } = req.query;
    const filter = { source: decodeURIComponent(source) };
    if (level) filter.level = level;
    if (topic) filter.topic = topic;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const words = await Word.find(filter).skip(skip).limit(parseInt(limit)).sort({ frequency_rank: 1 });
    const total = await Word.countDocuments(filter);

    return successResponse(res, { words, total, page: parseInt(page), pages: Math.ceil(total / parseInt(limit)) });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/words/topic/:topic
 */
exports.getByTopic = async (req, res) => {
  try {
    const { topic } = req.params;
    const { level, source, page = 1, limit = 20 } = req.query;
    const filter = { topic: decodeURIComponent(topic) };
    if (level) filter.level = level;
    if (source) filter.source = source;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const words = await Word.find(filter).skip(skip).limit(parseInt(limit));
    const total = await Word.countDocuments(filter);

    return successResponse(res, { words, total });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/words/level/:level
 */
exports.getByLevel = async (req, res) => {
  try {
    const words = await Word.find({ level: req.params.level }).limit(50);
    return successResponse(res, { words, total: words.length });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/words/topics/list
 * Get unique topics with stats for a source+level combo
 */
exports.getTopics = async (req, res) => {
  try {
    const { source, level } = req.query;
    const filter = {};
    if (source) filter.source = source;
    if (level) filter.level = level;

    const topics = await Word.aggregate([
      { $match: filter },
      { $group: { _id: '$topic', total: { $sum: 1 } } },
      { $sort: { total: -1 } },
    ]);

    // If user auth, enrich with progress (filtered by current source and level)
    let progressMap = {};
    if (req.user) {
      const wordFilter = {};
      if (source) wordFilter.source = source;
      if (level) wordFilter.level = level;
      
      const targetWords = await Word.find(wordFilter).select('_id topic');
      const targetWordIds = targetWords.map(w => w._id);

      const progresses = await Progress.find({
        user: req.user._id,
        word: { $in: targetWordIds }
      }).populate('word', 'topic');

      for (const p of progresses) {
        if (!p.word) continue;
        const t = p.word.topic;
        if (!progressMap[t]) progressMap[t] = { mastered: 0, learning: 0, reviewing: 0 };
        progressMap[t][p.status] = (progressMap[t][p.status] || 0) + 1;
      }
    }

    const enriched = topics.map((t) => {
      const mastered = progressMap[t._id]?.mastered || 0;
      const learning = (progressMap[t._id]?.learning || 0) + (progressMap[t._id]?.reviewing || 0);
      const totalStudied = mastered + learning;
      
      return {
        topic: t._id,
        total: t.total,
        mastered: mastered,
        learning: learning,
        new: Math.max(0, t.total - totalStudied),
      };
    });

    return successResponse(res, { topics: enriched });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/words/sources/list
 * Get all sources with total word counts and user progress
 */
exports.getSources = async (req, res) => {
  try {
    const { level } = req.query;
    const matchStage = {};
    if (level) {
      matchStage.level = level;
    }

    const sources = await Word.aggregate([
      { $match: matchStage },
      { $group: { _id: '$source', total: { $sum: 1 } } },
      { $sort: { total: -1 } },
    ]);

    let progressMap = {};
    if (req.user) {
      const progresses = await Progress.find({ user: req.user._id }).populate({
        path: 'word',
        match: matchStage,
        select: 'source level'
      });

      for (const p of progresses) {
        if (!p.word) continue;
        const s = p.word.source;
        if (!progressMap[s]) progressMap[s] = { mastered: 0, learning: 0 };
        if (p.status === 'mastered') progressMap[s].mastered += 1;
        else progressMap[s].learning += 1;
      }
    }

    const enriched = sources.map((s) => {
      const mastered = progressMap[s._id]?.mastered || 0;
      const learning = progressMap[s._id]?.learning || 0; // learning + reviewing
      const totalLearned = mastered + learning;

      return {
        source: s._id,
        total: s.total,
        learned: totalLearned,
        mastered: mastered,
        percentage: s.total > 0
          ? Math.round((totalLearned / s.total) * 100)
          : 0,
      };
    });

    return successResponse(res, { sources: enriched });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};
