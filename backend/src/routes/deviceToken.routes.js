const express = require('express');
const { register, remove } = require('../controllers/deviceToken.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = express.Router();

// Register a device token (POST /api/device-tokens)
router.post('/', authenticate, register);

// Remove a device token (DELETE /api/device-tokens/:token)
router.delete('/:token', authenticate, remove);

module.exports = router;
