const express = require("express");

const { authenticate, authorize } = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validate");
const {
    createPrescription: createPrescriptionValidator,
    prescriptionParam,
    listMyPrescriptions: listMyPrescriptionsValidator,
    listPrescriptions: listPrescriptionsValidator
} = require("../validators/prescription.validator");
const {
    createPrescription,
    listPrescriptions,
    listMyPrescriptions,
    getPrescriptionById,
    listDoctorPrescriptions
} = require("../controllers/prescription.controller");

const router = express.Router();

router.post("/", authenticate, authorize("DOCTOR"), validate(createPrescriptionValidator), createPrescription);
router.get("/", authenticate, authorize("ADMIN"), validate(listPrescriptionsValidator), listPrescriptions);
router.get("/me", authenticate, authorize("PATIENT"), validate(listMyPrescriptionsValidator), listMyPrescriptions);
router.get("/doctor", authenticate, authorize("DOCTOR"), validate(listMyPrescriptionsValidator), listDoctorPrescriptions);
router.get("/:id", authenticate, authorize("PATIENT", "DOCTOR", "ADMIN"), validate(prescriptionParam), getPrescriptionById);

module.exports = router;