const Favorite = require('../models/Favorite');
const { successResponse, errorResponse } = require('../utils/helpers');

/**
 * GET /api/favorite
 * Get all favorites for current user
 */
exports.getFavorites = async (req, res) => {
  try {
    const favorites = await Favorite.find({ user: req.user._id })
      .populate('word')
      .sort({ createdAt: -1 });
    return successResponse(res, { favorites, total: favorites.length });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * POST /api/favorite/:wordId
 * Add a word to favorites
 */
exports.addFavorite = async (req, res) => {
  try {
    const { wordId } = req.params;
    const exists = await Favorite.findOne({ user: req.user._id, word: wordId });
    if (exists) return errorResponse(res, 'Already in favorites', 409);

    const favorite = await Favorite.create({ user: req.user._id, word: wordId });
    await favorite.populate('word');
    return successResponse(res, { favorite }, 'Added to favorites', 201);
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * DELETE /api/favorite/:wordId
 * Remove a word from favorites
 */
exports.removeFavorite = async (req, res) => {
  try {
    const { wordId } = req.params;
    const deleted = await Favorite.findOneAndDelete({ user: req.user._id, word: wordId });
    if (!deleted) return errorResponse(res, 'Favorite not found', 404);
    return successResponse(res, null, 'Removed from favorites');
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/favorite/check/:wordId
 * Check if a word is favorited
 */
exports.checkFavorite = async (req, res) => {
  try {
    const exists = await Favorite.findOne({ user: req.user._id, word: req.params.wordId });
    return successResponse(res, { isFavorite: !!exists });
  } catch (err) {
    return errorResponse(res, 'Server error', 500);
  }
};
