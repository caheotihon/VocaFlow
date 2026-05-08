const router = require('express').Router();
const ctrl   = require('../controllers/stats.controller');
const { protect } = require('../middlewares/auth.middleware');

router.use(protect);

router.get('/dashboard', ctrl.getDashboard);

module.exports = router;
