const express = require("express");
const router = express.Router();
const pharmacyController = require("../controllers/pharmacy.controller");
const { protect, authorize } = require("../middleware/auth.middleware");

// Public (or just protected) route to sync pharmacy data offline
router.get("/list", protect, pharmacyController.list);

// Pharmacist role route to update inventory
router.post("/inventory", protect, authorize("PHARMACY"), pharmacyController.updateInventory);

module.exports = router;
