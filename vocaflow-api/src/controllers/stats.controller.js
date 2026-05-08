const Session = require('../models/Session');
const Progress = require('../models/Progress');
const User = require('../models/User');
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
    const totalLearned  = progresses.filter((p) => ['learning','reviewing','mastered'].includes(p.status)).length;
    const totalMastered = progresses.filter((p) => p.status === 'mastered').length;
    const totalReviewing = progresses.filter((p) => p.status === 'reviewing').length;
    const dueToday = progresses.filter((p) => p.next_review <= new Date() && p.status !== 'mastered').length;

    // ── Accuracy ─────────────────────────────────────────────────────
    const totalSeen    = progresses.reduce((a, p) => a + p.times_seen, 0);
    const totalCorrect = progresses.reduce((a, p) => a + p.times_correct, 0);
    const accuracy     = totalSeen > 0 ? Math.round((totalCorrect / totalSeen) * 100) : 0;

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
        day: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.getDay() === 0 ? 6 : d.getDay() - 1],
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
      heatmap[key] = (heatmap[key] || 0) + s.correct_answers;
    }

    // ── Recent sessions ───────────────────────────────────────────────
    const recentSessions = await Session.find({ user: userId, status: 'completed' })
      .sort({ completed_at: -1 })
      .limit(5);

    return successResponse(res, {
      user: {
        name: req.user.name,
        streakDays: req.user.streakDays,
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
      },
      study: {
        totalStudySeconds,
        totalStudyHours: Math.round(totalStudySeconds / 3600),
        totalSessions: allSessions.length,
      },
      weeklyData,
      heatmap,
      recentSessions,
    });
  } catch (err) {
    console.error('[Stats/dashboard]', err.message);
    return errorResponse(res, 'Server error', 500);
  }
};
