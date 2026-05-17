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

    let wordsToStudy = [];

    if (source === 'ReviewWrong') {
      const userId = req.user._id;
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const wrongProgresses = await Progress.find({
        user: userId,
        updatedAt: { $gte: today },
        times_wrong: { $gt: 0 }
      }).populate('word').limit(count);

      wordsToStudy = wrongProgresses.map((p) => p.word).filter(Boolean);

      if (wordsToStudy.length === 0) {
        const difficultProgresses = await Progress.find({
          user: userId,
          times_wrong: { $gt: 0 }
        }).populate('word').limit(count);
        wordsToStudy = difficultProgresses.map((p) => p.word).filter(Boolean);
      }
    } else if (source === 'Review') {

      // 1. Spaced Repetition Due (next_review <= now, status !== mastered)
      const dueProgresses = await Progress.find({
        user: userId,
        next_review: { $lte: new Date() },
        status: { $ne: 'mastered' },
      }).populate('word').limit(20);

      // 2. Words studied today
      const todayProgresses = await Progress.find({
        user: userId,
        updatedAt: { $gte: today }
      }).populate('word').limit(20);

      // 3. Difficult words (high incorrect rate or times_incorrect >= 2)
      const difficultProgresses = await Progress.find({
        user: userId,
        times_incorrect: { $gte: 2 }
      }).populate('word').limit(20);

      // Combine and deduplicate
      const uniqueWordIds = new Set();
      const reviewWords = [];

      const addWord = (progressItem) => {
        if (progressItem && progressItem.word) {
          const wId = progressItem.word._id.toString();
          if (!uniqueWordIds.has(wId)) {
            uniqueWordIds.add(wId);
            reviewWords.push(progressItem.word);
          }
        }
      };

      // Add in order
      todayProgresses.forEach(addWord);
      dueProgresses.forEach(addWord);
      difficultProgresses.forEach(addWord);

      wordsToStudy = reviewWords.slice(0, count);

      // Fallback if no review words
      if (wordsToStudy.length === 0) {
        const anyProgress = await Progress.find({ user: userId }).populate('word').limit(count);
        wordsToStudy = anyProgress.map(p => p.word).filter(Boolean);
      }
    } else {
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

      wordsToStudy = dueProgress.map((p) => p.word).filter(Boolean);

      // Fill remaining with new words (not yet seen)
      if (wordsToStudy.length < count) {
        const seenIds = dueProgress.map((p) => p.word?._id?.toString()).filter(Boolean);
        const newWords = allWords
          .filter((w) => !seenIds.includes(w._id.toString()))
          .slice(0, count - wordsToStudy.length);
        wordsToStudy = [...wordsToStudy, ...newWords];
      }
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
    let dailyGoalMet = false;
    let newlyLearned = false;
    let user = null;

    if (session) {
      if (is_correct) {
        session.correct_answers += 1;
        user = await User.findById(req.user._id);
        if (user) {
          if (!user.wordsLearnedToday.includes(word_id)) {
            user.wordsLearnedToday.push(word_id);
            newlyLearned = true;

            // Track in session's correct_new_words
            if (!session.correct_new_words.includes(word_id)) {
              session.correct_new_words.push(word_id);
            }

            // Check if goal met
            if (user.wordsLearnedToday.length >= user.dailyGoal && !user.dailyGoalClaimed) {
              user.dailyGoalClaimed = true;
              user.totalXP += 50; // Daily Goal Met Bonus!
              user.dailyXP += 50;
              dailyGoalMet = true;
            }
            await user.save();
          }
        }
      } else {
        session.wrong_answers += 1;
      }
      await session.save();
    }

    return successResponse(res, {
      progress: {
        status: progress.status,
        mastery: progress.mastery,
        next_review: progress.next_review,
      },
      dailyProgress: {
        dailyWordsLearned: user ? user.wordsLearnedToday.length : (req.user.wordsLearnedToday ? req.user.wordsLearnedToday.length : 0),
        dailyGoal: user ? user.dailyGoal : req.user.dailyGoal,
        dailyGoalClaimed: user ? user.dailyGoalClaimed : req.user.dailyGoalClaimed,
        newlyLearned,
        dailyGoalMet,
      }
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
    
    // XP based on unique new words correct today to prevent spamming
    const uniqueCorrectCount = session.correct_new_words && session.correct_new_words.length > 0 
      ? session.correct_new_words.length 
      : session.correct_answers;
    
    const xp = calcXP(uniqueCorrectCount, session.total_words);

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
    const streakResult = user.updateStreak();

    // Award badges (XP milestone)
    if (user.totalXP >= 1000 && !user.badges.includes('XP Master')) {
      user.badges.push('XP Master');
    }
    if (user.totalXP >= 5000 && !user.badges.includes('XP Legend')) {
      user.badges.push('XP Legend');
    }
    await user.save();

    // Check if daily goal was achieved during this session
    const correctNewCount = session.correct_new_words ? session.correct_new_words.length : 0;
    const learnedBefore = user.wordsLearnedToday.length - correctNewCount;
    const dailyGoalMet = learnedBefore < user.dailyGoal && user.wordsLearnedToday.length >= user.dailyGoal;

    return successResponse(res, {
      accuracy,
      xp_earned: xp,
      total_xp: user.totalXP,
      streak: user.streakDays,
      bestStreak: user.bestStreak || 0,
      correct: session.correct_answers,
      wrong: session.wrong_answers,
      total: session.total_words,
      milestoneReached: streakResult?.milestoneReached || null,
      dailyProgress: {
        dailyWordsLearned: user.wordsLearnedToday.length,
        dailyGoal: user.dailyGoal,
        dailyGoalClaimed: user.dailyGoalClaimed,
        dailyGoalMet,
      }
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
    const userId = req.user._id;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // 1. Spaced Repetition Due (next_review <= now, status !== mastered)
    const dueProgresses = await Progress.find({
      user: userId,
      next_review: { $lte: new Date() },
      status: { $ne: 'mastered' },
    }).populate('word').limit(30);

    // 2. Words studied today
    const todayProgresses = await Progress.find({
      user: userId,
      updatedAt: { $gte: today }
    }).populate('word').limit(30);

    // 3. Difficult words (high incorrect rate or times_incorrect >= 2)
    const difficultProgresses = await Progress.find({
      user: userId,
      times_incorrect: { $gte: 2 }
    }).populate('word').limit(30);

    // Combine and deduplicate
    const uniqueWordIds = new Set();
    const reviewWords = [];

    const addWord = (progressItem) => {
      if (progressItem && progressItem.word) {
        const wId = progressItem.word._id.toString();
        if (!uniqueWordIds.has(wId)) {
          uniqueWordIds.add(wId);
          reviewWords.push(progressItem.word);
        }
      }
    };

    // Add in order: today's words first, then due words, then difficult ones
    todayProgresses.forEach(addWord);
    dueProgresses.forEach(addWord);
    difficultProgresses.forEach(addWord);

    // Limit to max 50 words to avoid overwhelming
    const finalWords = reviewWords.slice(0, 50);

    return successResponse(res, { 
      words: finalWords, 
      total: finalWords.length 
    });
  } catch (err) {
    console.error('[Learn/review-today]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/learn/last-active
 * Get the user's most recent active learning session
 */
exports.getLastActiveSession = async (req, res) => {
  try {
    const session = await Session.findOne({
      user: req.user._id,
      status: 'active'
    }).sort({ updatedAt: -1 }).populate('words_studied');

    if (!session) {
      return successResponse(res, { session: null }, 'No active session found');
    }

    return successResponse(res, { session }, 'Active session found');
  } catch (err) {
    console.error('[Learn/last-active]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/learn/today-history
 * Get learning history stats and words list for today
 */
exports.getTodayHistory = async (req, res) => {
  try {
    const userId = req.user._id;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // 1. Get all progresses updated today
    const progresses = await Progress.find({
      user: userId,
      updatedAt: { $gte: today }
    }).populate('word');

    // 2. Filter correct and wrong words
    const correctWords = [];
    const wrongWords = [];

    progresses.forEach((p) => {
      if (p.word) {
        if (p.times_wrong > 0) {
          wrongWords.push(p.word);
        } else {
          correctWords.push(p.word);
        }
      }
    });

    // 3. Get sessions completed today
    const sessions = await Session.find({
      user: userId,
      status: 'completed',
      completed_at: { $gte: today }
    });

    const totalXP = sessions.reduce((sum, s) => sum + (s.xp_earned || 0), 0);
    const totalWords = progresses.length;
    const accuracy = totalWords > 0 
      ? Math.round((correctWords.length / totalWords) * 100) 
      : 0;

    return successResponse(res, {
      stats: {
        totalWords,
        correctCount: correctWords.length,
        wrongCount: wrongWords.length,
        accuracy,
        totalXP,
      },
      correctWords,
      wrongWords,
    }, 'Today history retrieved');
  } catch (err) {
    console.error('[Learn/today-history]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};
