const express = require('express');
const router = express.Router();
const { protect, isAdmin } = require('../middlewares/auth.middleware');
const adminController = require('../controllers/admin.controller');

// Secure all admin routes to only logged in admins
router.use(protect, isAdmin);

// Analytics
router.get('/stats', adminController.getDashboardStats);

// User Moderation
router.get('/users', adminController.getUsers);
router.post('/users/:id/toggle', adminController.toggleUserStatus);

// Vocabulary CRUD
router.post('/words', adminController.createWord);
router.put('/words/:id', adminController.updateWord);
router.delete('/words/:id', adminController.deleteWord);

module.exports = router;
