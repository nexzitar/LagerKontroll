const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate, requireAdmin } = require('../middleware/auth');

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);

// Protected routes (require authentication)
router.get('/me', authenticate, authController.getCurrentUser);
router.post('/change-password', authenticate, authController.changePassword);

// Admin routes (require admin privileges)
router.get('/users', authenticate, requireAdmin, authController.getAllUsers);
router.post('/users', authenticate, requireAdmin, authController.createUser);
router.put('/users/:userId/role', authenticate, requireAdmin, authController.updateUserRole);
router.delete('/users/:userId', authenticate, requireAdmin, authController.deleteUser);

module.exports = router;
