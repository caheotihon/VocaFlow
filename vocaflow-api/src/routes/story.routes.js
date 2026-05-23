const router = require('express').Router();
const ctrl = require('../controllers/story.controller');
const { protect } = require('../middlewares/auth.middleware');

router.use(protect); // all story routes require auth

router.post('/generate', ctrl.generateStory);
router.get('/', ctrl.getStories);
router.get('/:id', ctrl.getStoryById);
router.post('/:id/complete', ctrl.completeStoryQuiz);
router.delete('/:id', ctrl.deleteStory);

module.exports = router;
