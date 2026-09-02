const express = require("express");

const { authenticate, authorize } = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validate");
const { createPatient, updatePatient, listPatients } = require("../validators/patient.validator");
const {
    createPatient: createPatientCtrl,
    getMyPatient,
    updateMyPatient,
    listPatients: listPatientsCtrl,
    getPatientById
} = require("../controllers/patient.controller");

const router = express.Router();

router.post("/", authenticate, authorize("PATIENT"), validate(createPatient), createPatientCtrl);
router.get("/me", authenticate, authorize("PATIENT"), getMyPatient);
router.patch("/me", authenticate, authorize("PATIENT"), validate(updatePatient), updateMyPatient);

router.get("/", authenticate, authorize("ADMIN"), validate(listPatients), listPatientsCtrl);
router.get("/:id", authenticate, authorize("ADMIN"), getPatientById);

module.exports = router;
