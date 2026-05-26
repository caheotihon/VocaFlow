const User = require('../models/User');
const Word = require('../models/Word');
const Story = require('../models/Story');
const Progress = require('../models/Progress');

/**
 * Get aggregated analytics stats for the admin dashboard
 */
const getDashboardStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    
    // Active today: lastActiveDate is within today
    const startOfToday = new Date();
    startOfToday.setUTCHours(0, 0, 0, 0);
    const activeToday = await User.countDocuments({
      lastActiveDate: { $gte: startOfToday }
    });

    const totalWords = await Word.countDocuments();
    const totalStories = await Story.countDocuments();

    // Average user XP
    const xpAgg = await User.aggregate([
      { $group: { _id: null, avgXp: { $avg: '$totalXP' } } }
    ]);
    const avgXp = xpAgg.length > 0 ? Math.round(xpAgg[0].avgXp) : 0;

    // CEFR distribution in vocabulary db
    const cefrAgg = await Word.aggregate([
      { $group: { _id: '$level', count: { $sum: 1 } } }
    ]);
    const cefrDistribution = {};
    for (const item of cefrAgg) {
      if (item._id) {
        cefrDistribution[item._id] = item.count;
      }
    }

    res.json({
      success: true,
      data: {
        totalUsers,
        activeToday,
        activeUsersToday: activeToday, // For Flutter compatibility
        totalWords,
        totalStories,
        avgXp,
        averageXp: avgXp, // For Flutter compatibility
        cefrDistribution
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/**
 * Get all registered users list
 */
const getUsers = async (req, res) => {
  try {
    const users = await User.find({})
      .select('name email role streakDays totalXP isActive createdAt')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: {
        users: users // Wrapped in object as expected by Flutter: res.data['data']['users']
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/**
 * Toggle active/inactive status of a user
 */
const toggleUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (id === req.user._id.toString()) {
      return res.status(400).json({ success: false, message: 'You cannot deactivate your own admin account.' });
    }

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.isActive = !user.isActive;
    await user.save();

    res.json({
      success: true,
      message: `User de/activated successfully. New status: ${user.isActive}`,
      data: { id: user._id, isActive: user.isActive }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/**
 * Create a new standard word
 */
const createWord = async (req, res) => {
  try {
    const {
      word, meaningVn, meaning_vn, partOfSpeech, level,
      definition, definition_vn, definition_en, example, pronunciation, source, topic
    } = req.body;

    const actualWord = word;
    const actualMeaningVn = meaning_vn || meaningVn;
    const actualPartOfSpeech = partOfSpeech;
    const actualLevel = level;

    if (!actualWord || !actualMeaningVn || !actualPartOfSpeech || !actualLevel) {
      return res.status(400).json({ success: false, message: 'Required fields: word, meaning_vn, partOfSpeech, level' });
    }

    const newWord = await Word.create({
      word: actualWord.trim(),
      meaning_vn: actualMeaningVn.trim(),
      partOfSpeech: actualPartOfSpeech.trim(),
      level: actualLevel.trim().toUpperCase(),
      definition_vn: (definition_vn || definition || '').trim(),
      definition_en: (definition_en || '').trim(),
      example: example ? example.trim() : '',
      pronunciation: pronunciation ? pronunciation.trim() : '',
      source: source ? source.trim() : 'Oxford 3000',
      topic: topic ? topic.trim() : 'General'
    });

    res.status(201).json({
      success: true,
      message: 'Vocabulary word created successfully! 🚀',
      data: newWord
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/**
 * Update an existing word
 */
const updateWord = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const updatedWord = await Word.findByIdAndUpdate(id, updates, { new: true, runValidators: true });
    if (!updatedWord) {
      return res.status(404).json({ success: false, message: 'Word not found' });
    }

    res.json({
      success: true,
      message: 'Word updated successfully!',
      data: updatedWord
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/**
 * Delete a word
 */
const deleteWord = async (req, res) => {
  try {
    const { id } = req.params;

    const deletedWord = await Word.findByIdAndDelete(id);
    if (!deletedWord) {
      return res.status(404).json({ success: false, message: 'Word not found' });
    }

    res.json({
      success: true,
      message: 'Word deleted successfully!'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = {
  getDashboardStats,
  getUsers,
  toggleUserStatus,
  createWord,
  updateWord,
  deleteWord
};
