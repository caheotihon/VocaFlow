const Word = require('../models/Word');
const Progress = require('../models/Progress');
const Session = require('../models/Session');
const User = require('../models/User');
const { successResponse, errorResponse, calcXP } = require('../utils/helpers');

/**
 * POST /api/learn/start
 * Start a new learning session — returns words to study
 */
exports.startSession = async (req, res) => {
  try {
    const { source, level, topic, mode, count = 10 } = req.body;
    if (!source || !mode) return errorResponse(res, 'source and mode are required', 400);

    // Build word filter
    const filter = { source };
    if (level) filter.level = level;
    if (topic) filter.topic = topic;

    // Get words the user needs to review OR hasn't seen yet
    const allWords = await Word.find(filter).limit(200);
    const wordIds = allWords.map((w) => w._id);

    // Words due for review
    const dueProgress = await Progress.find({
      user: req.user._id,
      word: { $in: wordIds },
      next_review: { $lte: new Date() },
      status: { $ne: 'mastered' },
    }).populate('word').limit(count);

    let wordsToStudy = dueProgress.map((p) => p.word).filter(Boolean);

    // Fill remaining with new words (not yet seen)
    if (wordsToStudy.length < count) {
      const seenIds = dueProgress.map((p) => p.word?._id?.toString()).filter(Boolean);
      const newWords = allWords
        .filter((w) => !seenIds.includes(w._id.toString()))
        .slice(0, count - wordsToStudy.length);
      wordsToStudy = [...wordsToStudy, ...newWords];
    }

    // Create session record
    const session = await Session.create({
      user: req.user._id,
      source,
      level,
      topic,
      mode,
      total_words: wordsToStudy.length,
      words_studied: wordsToStudy.map((w) => w._id),
    });

    return successResponse(res, {
      session_id: session._id,
      words: wordsToStudy,
      total: wordsToStudy.length,
    }, 'Session started');
  } catch (err) {
    console.error('[Learn/start]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * POST /api/learn/result
 * Submit answer results for a word in a session
 */
exports.submitResult = async (req, res) => {
  try {
    const { session_id, word_id, is_correct, time_taken_ms } = req.body;
    if (!session_id || !word_id) return errorResponse(res, 'session_id and word_id required', 400);

    // Update or create progress record
    let progress = await Progress.findOne({ user: req.user._id, word: word_id });
    if (!progress) {
      progress = new Progress({ user: req.user._id, word: word_id });
    }

    progress.times_seen += 1;
    if (is_correct) {
      progress.times_correct += 1;
    } else {
      progress.times_wrong += 1;
    }

    // SM-2 quality: 5 = perfect, 2 = wrong
    const quality = is_correct ? 5 : 2;
    progress.applySpacedRepetition(quality);
    await progress.save();

    // Update session
    const session = await Session.findById(session_id);
    if (session) {
      if (is_correct) session.correct_answers += 1;
      else session.wrong_answers += 1;
      await session.save();
    }

    return successResponse(res, {
      progress: {
        status: progress.status,
        mastery: progress.mastery,
        next_review: progress.next_review,
      },
    }, 'Result submitted');
  } catch (err) {
    console.error('[Learn/result]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * POST /api/learn/complete
 * Mark a session as complete and update user XP + streak
 */
exports.completeSession = async (req, res) => {
  try {
    const { session_id, duration_seconds } = req.body;
    const session = await Session.findById(session_id);
    if (!session) return errorResponse(res, 'Session not found', 404);

    const accuracy = session.total_words > 0
      ? Math.round((session.correct_answers / session.total_words) * 100)
      : 0;
    const xp = calcXP(session.correct_answers, session.total_words);

    session.accuracy = accuracy;
    session.xp_earned = xp;
    session.duration_seconds = duration_seconds || 0;
    session.status = 'completed';
    session.completed_at = new Date();
    await session.save();

    // Update user XP and streak
    const user = await User.findById(req.user._id);
    user.totalXP += xp;
    user.dailyXP += xp;
    user.updateStreak();

    // Award badges
    if (user.streakDays >= 7 && !user.badges.includes('7-Day Streak')) {
      user.badges.push('7-Day Streak');
    }
    if (user.totalXP >= 1000 && !user.badges.includes('XP Master')) {
      user.badges.push('XP Master');
    }
    await user.save();

    return successResponse(res, {
      accuracy,
      xp_earned: xp,
      total_xp: user.totalXP,
      streak: user.streakDays,
      correct: session.correct_answers,
      wrong: session.wrong_answers,
      total: session.total_words,
    }, 'Session completed! 🎉');
  } catch (err) {
    console.error('[Learn/complete]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/learn/progress
 * Get user's overall learning progress
 */
exports.getProgress = async (req, res) => {
  try {
    const { source, level, topic } = req.query;
    const filter = { user: req.user._id };

    const progresses = await Progress.find(filter).populate({
      path: 'word',
      match: {
        ...(source && { source }),
        ...(level && { level }),
        ...(topic && { topic }),
      },
    });

    const valid = progresses.filter((p) => p.word);
    const summary = {
      total: valid.length,
      new: valid.filter((p) => p.status === 'new').length,
      learning: valid.filter((p) => p.status === 'learning').length,
      reviewing: valid.filter((p) => p.status === 'reviewing').length,
      mastered: valid.filter((p) => p.status === 'mastered').length,
    };

    return successResponse(res, { summary, progresses: valid });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/learn/review-today
 * Get words due for review today
 */
exports.getReviewToday = async (req, res) => {
  try {
    const due = await Progress.find({
      user: req.user._id,
      next_review: { $lte: new Date() },
      status: { $ne: 'mastered' },
    }).populate('word').limit(50);

    const words = due.map((p) => p.word).filter(Boolean);
    return successResponse(res, { words, total: words.length });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};
