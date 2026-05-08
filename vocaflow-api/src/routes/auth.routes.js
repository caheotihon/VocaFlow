const router = require('express').Router();
const ctrl   = require('../controllers/auth.controller');
const { protect } = require('../middlewares/auth.middleware');

router.post('/register',  ctrl.register);
router.post('/login',     ctrl.login);
router.post('/google',    ctrl.googleLogin);
router.get('/me',         protect, ctrl.getMe);
router.put('/profile',    protect, ctrl.updateProfile);

module.exports = router;
