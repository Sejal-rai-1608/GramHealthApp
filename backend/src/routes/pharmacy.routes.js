const express = require("express");
const router = express.Router();
const pharmacyController = require("../controllers/pharmacy.controller");
const { authenticate, authorize } = require("../middleware/auth.middleware");

// Public (or just protected) route to sync pharmacy data offline
router.get("/list", authenticate, pharmacyController.list);

// Pharmacist role route to update inventory
router.post("/inventory", authenticate, authorize("PHARMACY"), pharmacyController.updateInventory);

module.exports = router;
