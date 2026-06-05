const express = require('express');
const router = express.Router();
const trailerController = require('../controllers/trailerController');
const { upload, processImage } = require('../middleware/upload');
const { authenticate, requireAdmin, requireWrite } = require('../middleware/auth');

// Create a new trailer entry (with photo upload) - requires write permissions
router.post(
  '/trailers',
  authenticate,
  requireWrite,
  upload.single('photo'),
  processImage,
  trailerController.createTrailerEntry
);

// Get all trailers (with pagination and filtering) - requires authentication (read access)
router.get('/trailers', authenticate, trailerController.getTrailers);

// Get a specific trailer's latest entry - requires authentication (read access)
router.get('/trailers/:id', authenticate, trailerController.getTrailerById);

// Get trailer history - requires authentication (read access)
router.get('/trailers/:id/entries', authenticate, trailerController.getTrailerHistory);

// Update trailer status (without new photo) - requires write permissions
router.put('/trailers/:id/status', authenticate, requireWrite, trailerController.updateTrailerStatus);

// Update trailer number (rename) - requires write permissions
router.put('/trailers/:id/number', authenticate, requireWrite, trailerController.updateTrailerNumber);

// Delete a trailer and all its entries - requires admin
router.delete('/trailers/:id', authenticate, requireAdmin, trailerController.deleteTrailer);

module.exports = router;
