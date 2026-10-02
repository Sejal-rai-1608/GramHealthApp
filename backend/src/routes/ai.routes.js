const express = require("express");
const router = express.Router();
const { queryAi } = require("../controllers/ai.controller");
const { protect } = require("../middleware/auth.middleware");

// POST /api/ai/query
router.post("/query", protect, queryAi);

module.exports = router;
