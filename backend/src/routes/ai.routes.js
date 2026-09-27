const express = require('express');
const { authenticate } = require('../middleware/auth.middleware');
const { queryAi } = require('../controllers/ai.controller');

const router = express.Router();

router.post(
  '/query',
  authenticate,
  (req, res, next) => {
    const requestId = req.headers['x-request-id'] || 'NO_REQ_ID';
    const userId = req.user ? (req.user.userId || req.user.id) : 'UNAUTHENTICATED';
    const queryLength = req.body && req.body.query ? req.body.query.length : 0;

    console.log('[AI Route] POST /api/ai/query received');
    console.log(`[Node AI Route] Request ID: ${requestId}`);
    console.log(`[Node AI Route] POST /api/ai/query`);
    console.log(`[Node AI Route] authenticated user ID: ${userId}`);
    console.log(`[Node AI Route] query length: ${queryLength}`);

    next();
  },
  queryAi
);

module.exports = router;
