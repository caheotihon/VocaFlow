const Session = require('../models/Session');
const Progress = require('../models/Progress');
const User = require('../models/User');
const Word = require('../models/Word');
const { successResponse, errorResponse } = require('../utils/helpers');

/**
 * GET /api/stats/dashboard
 * Full stats dashboard for the current user
 */
exports.getDashboard = async (req, res) => {
  try {
    const userId = req.user._id;

    // ── Progress summary ──────────────────────────────────────────────
    const progresses = await Progress.find({ user: userId });
    const totalLearned = progresses.filter((p) => ['learning', 'reviewing', 'mastered'].includes(p.status)).length;
    const totalMastered = progresses.filter((p) => p.status === 'mastered').length;
    const totalReviewing = progresses.filter((p) => p.status === 'reviewing').length;
    const dueToday = progresses.filter((p) => p.next_review <= new Date() && p.status !== 'mastered').length;

    // ── Accuracy ─────────────────────────────────────────────────────
    const totalSeen = progresses.reduce((a, p) => a + p.times_seen, 0);
    const totalCorrect = progresses.reduce((a, p) => a + p.times_correct, 0);
    const accuracy = totalSeen > 0 ? Math.round((totalCorrect / totalSeen) * 100) : 0;

    // ── Weekly chart (last 7 days) ────────────────────────────────────
    const weekSessions = await Session.find({
      user: userId,
      status: 'completed',
      completed_at: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
    });

    const weeklyData = Array.from({ length: 7 }, (_, i) => {
      const d = new Date();
      d.setDate(d.getDate() - (6 - i));
      d.setHours(0, 0, 0, 0);
      const nextDay = new Date(d);
      nextDay.setDate(nextDay.getDate() + 1);

      const daySessions = weekSessions.filter((s) => {
        const t = new Date(s.completed_at);
        return t >= d && t < nextDay;
      });

      return {
        day: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.getDay() === 0 ? 6 : d.getDay() - 1],
        words: daySessions.reduce((a, s) => a + s.correct_answers, 0),
        xp: daySessions.reduce((a, s) => a + s.xp_earned, 0),
        date: d.toISOString().split('T')[0],
      };
    });

    // ── Total study time ──────────────────────────────────────────────
    const allSessions = await Session.find({ user: userId, status: 'completed' });
    const totalStudySeconds = allSessions.reduce((a, s) => a + (s.duration_seconds || 0), 0);

    // ── Activity heatmap (last 30 days) ──────────────────────────────
    const heatmapSessions = await Session.find({
      user: userId,
      status: 'completed',
      completed_at: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
    });

    const heatmap = {};
    for (const s of heatmapSessions) {
      const key = new Date(s.completed_at).toISOString().split('T')[0];
      heatmap[key] = (heatmap[key] || 0) + 1;
    }

    // ── Recent sessions ───────────────────────────────────────────────
    const recentSessions = await Session.find({ user: userId, status: 'completed' })
      .sort({ completed_at: -1 })
      .limit(5);

    // ── Resume Study Engine ───────────────────────────────────────────
    const activeSession = await Session.findOne({
      user: userId,
      status: 'active'
    }).sort({ updatedAt: -1 }).populate('words_studied');

    let nextRecommendation = null;
    const lastCompletedSession = await Session.findOne({
      user: userId,
      status: 'completed'
    }).sort({ completed_at: -1 });

    if (!activeSession && lastCompletedSession) {
      const { source, level } = lastCompletedSession;

      // Get all topics for this source + level
      const matchFilter = { source };
      if (level) matchFilter.level = level;

      const topics = await Word.aggregate([
        { $match: matchFilter },
        { $group: { _id: '$topic', total: { $sum: 1 } } },
        { $sort: { total: -1 } },
      ]);

      // Enrich with progress
      let progressMap = {};
      const progresses = await Progress.find({ user: userId }).populate('word', 'topic source level');
      for (const p of progresses) {
        if (!p.word || p.word.source !== source || (level && p.word.level !== level)) continue;
        const t = p.word.topic;
        if (!progressMap[t]) progressMap[t] = { mastered: 0 };
        if (p.status === 'mastered') progressMap[t].mastered += 1;
      }

      // Find the first topic not fully mastered
      const nextTopicObj = topics.find((t) => {
        const mastered = progressMap[t._id]?.mastered || 0;
        return mastered < t.total;
      });

      if (nextTopicObj) {
        nextRecommendation = {
          source,
          level,
          topic: nextTopicObj._id,
          mode: lastCompletedSession.mode,
        };
      }
    }

    return successResponse(res, {
      user: {
        name: req.user.name,
        streakDays: typeof req.user.getStreakForToday === 'function' ? req.user.getStreakForToday() : req.user.streakDays,
        bestStreak: req.user.bestStreak || 0,
        totalXP: req.user.totalXP,
        dailyXP: req.user.dailyXP,
        dailyGoal: req.user.dailyGoal,
        badges: req.user.badges,
      },
      progress: {
        totalLearned,
        totalMastered,
        totalReviewing,
        dueToday,
        accuracy,
        totalSeen,
        totalCorrect,
        dailyWordsLearned: req.user.wordsLearnedToday ? req.user.wordsLearnedToday.length : 0,
        dailyGoalClaimed: req.user.dailyGoalClaimed || false,
      },
      study: {
        totalStudySeconds,
        totalStudyHours: Math.round(totalStudySeconds / 3600),
        totalSessions: allSessions.length,
      },
      weeklyData,
      heatmap,
      recentSessions,
      resume: {
        activeSession: activeSession ? {
          session_id: activeSession._id,
          source: activeSession.source,
          level: activeSession.level,
          topic: activeSession.topic,
          mode: activeSession.mode,
          currentIndex: activeSession.correct_answers + activeSession.wrong_answers,
          total_words: activeSession.total_words,
          correct_answers: activeSession.correct_answers,
          wrong_answers: activeSession.wrong_answers,
        } : null,
        nextRecommendation,
      }
    });
  } catch (err) {
    console.error('[Stats/dashboard]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/stats/leaderboard
 * Top 20 users ranked by streakDays, then totalXP
 */
exports.getLeaderboard = async (req, res) => {
  try {
    const { type = 'streak' } = req.query; // streak | xp
    const sortField = type === 'xp' ? { totalXP: -1 } : { streakDays: -1, totalXP: -1 };

    const dbUsers = await User.find({ isActive: true })
      .select('name avatar streakDays bestStreak totalXP badges')
      .sort(sortField);

    let users = [...dbUsers];

    // Seed mock competitors if total users are low (e.g. less than 10) to make the leaderboard alive!
    if (dbUsers.length < 10) {
      const mockCompetitors = [
        { _id: 'mock_u1', name: 'Sophia Loren', streakDays: 15, bestStreak: 15, totalXP: 3100, badges: ['7-Day Streak'] },
        { _id: 'mock_u2', name: 'Alex Mercer', streakDays: 12, bestStreak: 12, totalXP: 2400, badges: ['7-Day Streak'] },
        { _id: 'mock_u3', name: 'Emma Watson', streakDays: 9, bestStreak: 9, totalXP: 1850, badges: [] },
        { _id: 'mock_u4', name: 'Lily Evans', streakDays: 8, bestStreak: 8, totalXP: 1400, badges: [] },
        { _id: 'mock_u5', name: 'David Beckham', streakDays: 6, bestStreak: 6, totalXP: 1200, badges: [] },
        { _id: 'mock_u6', name: 'James Bond', streakDays: 4, bestStreak: 5, totalXP: 850, badges: [] },
        { _id: 'mock_u7', name: 'Oliver Twist', streakDays: 3, bestStreak: 3, totalXP: 600, badges: [] },
        { _id: 'mock_u8', name: 'Harry Potter', streakDays: 18, bestStreak: 20, totalXP: 4500, badges: ['30-Day Streak', '7-Day Streak'] },
        { _id: 'mock_u9', name: 'Sherlock Holmes', streakDays: 25, bestStreak: 30, totalXP: 6200, badges: ['30-Day Streak', '7-Day Streak'] },
      ];

      const dbUserNames = new Set(dbUsers.map((u) => u.name.toLowerCase()));
      mockCompetitors.forEach((mc) => {
        if (!dbUserNames.has(mc.name.toLowerCase())) {
          users.push(mc);
        }
      });
    }

    // Sort combined list
    if (type === 'xp') {
      users.sort((a, b) => b.totalXP - a.totalXP);
    } else {
      users.sort((a, b) => {
        if (b.streakDays !== a.streakDays) {
          return b.streakDays - a.streakDays;
        }
        return b.totalXP - a.totalXP;
      });
    }

    // Keep top 20
    users = users.slice(0, 20);

    // Find current user's rank
    const currentUserId = req.user._id.toString();
    const rankedUsers = users.map((u, index) => ({
      rank: index + 1,
      _id: u._id,
      name: u.name,
      avatar: u.avatar,
      streakDays: u.streakDays,
      bestStreak: u.bestStreak || 0,
      totalXP: u.totalXP,
      badges: u.badges || [],
      isCurrentUser: u._id.toString() === currentUserId,
    }));

    // Get current user's actual rank if not in top 20
    const currentUserEntry = rankedUsers.find((u) => u.isCurrentUser);
    let currentUserRank = currentUserEntry?.rank || null;
    if (!currentUserRank) {
      const count = await User.countDocuments(
        type === 'xp'
          ? { totalXP: { $gt: req.user.totalXP }, isActive: true }
          : { streakDays: { $gt: req.user.streakDays }, isActive: true }
      );
      currentUserRank = count + 1;
    }

    return successResponse(res, {
      leaderboard: rankedUsers,
      currentUserRank,
      type,
    });
  } catch (err) {
    console.error('[Stats/leaderboard]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};
