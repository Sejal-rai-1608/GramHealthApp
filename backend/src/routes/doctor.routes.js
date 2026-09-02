const express = require("express");

const { authenticate, authorize } = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validate");
const { uuidParam } = require("../validators/common.validator");
const { createDoctor, updateDoctor, listDoctors } = require("../validators/doctor.validator");
const { listConsultations: listConsultationsValidator } = require("../validators/consultation.validator");
const { listMedicalRecords: listMedicalRecordsValidator } = require("../validators/medicalRecord.validator");
const { listDoctorPrescriptions: listDoctorPrescriptionsValidator } = require("../validators/prescription.validator");
const {
    createDoctor: createDoctorCtrl,
    getMyDoctor,
    updateMyDoctor,
    listDoctors: listDoctorsCtrl,
    getDoctorById,
    listDoctorConsultations
} = require("../controllers/doctor.controller");
const { listDoctorMedicalRecords } = require("../controllers/medicalRecord.controller");
const { listDoctorPrescriptions } = require("../controllers/prescription.controller");

const router = express.Router();

router.post("/", authenticate, authorize("DOCTOR"), validate(createDoctor), createDoctorCtrl);
router.get("/me", authenticate, authorize("DOCTOR"), getMyDoctor);
router.patch("/me", authenticate, authorize("DOCTOR"), validate(updateDoctor), updateMyDoctor);

router.get("/consultations", authenticate, authorize("DOCTOR"), validate(listConsultationsValidator), listDoctorConsultations);
router.get("/medical-records", authenticate, authorize("DOCTOR"), validate(listMedicalRecordsValidator), listDoctorMedicalRecords);
router.get("/prescriptions", authenticate, authorize("DOCTOR"), validate(listDoctorPrescriptionsValidator), listDoctorPrescriptions);
router.get("/", authenticate, authorize("PATIENT", "ASHA", "ADMIN"), validate(listDoctors), listDoctorsCtrl);
router.get("/:id", authenticate, authorize("PATIENT", "ASHA", "ADMIN"), validate(uuidParam()), getDoctorById);

module.exports = router;
