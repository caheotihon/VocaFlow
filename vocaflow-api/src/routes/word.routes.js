const router  = require('express').Router();
const ctrl    = require('../controllers/word.controller');
const { protect } = require('../middlewares/auth.middleware');

// Optional auth middleware (enriches with progress if logged in)
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const jwt  = require('jsonwebtoken');
      const User = require('../models/User');
      const decoded = jwt.verify(authHeader.split(' ')[1], process.env.JWT_SECRET);
      req.user = await User.findById(decoded.id);
    }
  } catch (_) { /* no-op */ }
  next();
};

// ⚠️ Specific routes MUST come before /:id
router.get('/random',        ctrl.getRandomWord);
router.get('/search',        ctrl.searchWords);
router.get('/sources/list',  optionalAuth, ctrl.getSources);
router.get('/topics/list',   optionalAuth, ctrl.getTopics);
router.get('/source/:source',optionalAuth, ctrl.getBySource);
router.get('/topic/:topic',  optionalAuth, ctrl.getByTopic);
router.get('/level/:level',  ctrl.getByLevel);
router.post('/ai-generate',  protect, ctrl.generateAIDeck);
router.get('/:id',           ctrl.getWordById);
router.get('/',              ctrl.getAllWords);

module.exports = router;
