const router = require('express').Router();
const ctrl   = require('../controllers/learn.controller');
const { protect } = require('../middlewares/auth.middleware');

router.use(protect); // all learn routes require auth

router.post('/start',         ctrl.startSession);
router.post('/result',        ctrl.submitResult);
router.post('/complete',      ctrl.completeSession);
router.post('/ai-story',      ctrl.generateAiStory);
router.get('/progress',       ctrl.getProgress);
router.get('/review-today',   ctrl.getReviewToday);
router.get('/today-history',  ctrl.getTodayHistory);
router.get('/last-active',    ctrl.getLastActiveSession);
router.get('/history',        ctrl.getSessionHistory);
router.get('/session/:id',    ctrl.getSessionDetails);

module.exports = router;
