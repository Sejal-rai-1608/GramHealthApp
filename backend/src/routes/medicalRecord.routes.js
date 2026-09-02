const express = require("express");

const { authenticate, authorize } = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validate");
const {
    createMedicalRecord: createMedicalRecordValidator,
    medicalRecordParam,
    listMedicalRecords: listMedicalRecordsValidator
} = require("../validators/medicalRecord.validator");
const {
    createMedicalRecord,
    listMyMedicalRecords,
    getMedicalRecordById
} = require("../controllers/medicalRecord.controller");

const router = express.Router();

router.post("/", authenticate, authorize("DOCTOR"), validate(createMedicalRecordValidator), createMedicalRecord);
router.get("/me", authenticate, authorize("PATIENT"), validate(listMedicalRecordsValidator), listMyMedicalRecords);
router.get("/:id", authenticate, authorize("PATIENT", "DOCTOR", "ADMIN"), validate(medicalRecordParam), getMedicalRecordById);

module.exports = router;
