const router = require('express').Router();
const ctrl   = require('../controllers/favorite.controller');
const { protect } = require('../middlewares/auth.middleware');

router.use(protect);

router.get('/',                  ctrl.getFavorites);
router.get('/check/:wordId',     ctrl.checkFavorite);
router.post('/:wordId',          ctrl.addFavorite);
router.delete('/:wordId',        ctrl.removeFavorite);

module.exports = router;
