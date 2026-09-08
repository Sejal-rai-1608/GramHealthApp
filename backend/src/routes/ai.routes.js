const express = require('express');
const { authenticate } = require('../middleware/auth.middleware');
const { queryAi } = require('../controllers/ai.controller');

const router = express.Router();

router.post('/query', authenticate, queryAi);

module.exports = router;
