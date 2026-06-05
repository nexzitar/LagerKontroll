const express = require('express');
const router = express.Router();
const appVersion = require('../config/appVersion');

// Public route - no authentication required
router.get('/version', (req, res) => {
  res.json(appVersion);
});

module.exports = router;
