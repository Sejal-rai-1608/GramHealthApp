const express = require("express");
const router = express.Router();
const { queryAi } = require("../controllers/ai.controller");
const { authenticate } = require("../middleware/auth.middleware");

// POST /api/ai/query
router.post("/query", authenticate, queryAi);

module.exports = router;
