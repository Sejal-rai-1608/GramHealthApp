const express = require("express");
const { authenticate, authorize } = require("../middleware/auth.middleware");
const reportCtrl = require("../controllers/report.controller");

const router = express.Router();

router.get("/overview", authenticate, authorize("ADMIN"), reportCtrl.getOverview);
router.get("/consultations", authenticate, authorize("ADMIN"), reportCtrl.getConsultationTrends);
router.get("/doctors", authenticate, authorize("ADMIN"), reportCtrl.getDoctorWorkload);
router.get("/pharmacies", authenticate, authorize("ADMIN"), reportCtrl.getPharmacyCoverage);
router.get("/user-growth", authenticate, authorize("ADMIN"), reportCtrl.getUserGrowth);

module.exports = router;