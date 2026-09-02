const express = require("express");

const { authenticate, authorize } = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validate");
const {
    createConsultation: createConsultationValidator,
    updateStatus: updateStatusValidator,
    acceptConsultation: acceptConsultationValidator,
    completeConsultation: completeConsultationValidator,
    assignDoctor: assignDoctorValidator,
    consultationParam,
    listConsultations: listConsultationsValidator
} = require("../validators/consultation.validator");
const {
    createConsultation,
    getConsultationById,
    listConsultations,
    updateStatus,
    acceptConsultation,
    completeConsultation,
    assignDoctor
} = require("../controllers/consultation.controller");

const router = express.Router();

router.post("/", authenticate, authorize("PATIENT", "ASHA"), validate(createConsultationValidator), createConsultation);
router.get("/", authenticate, authorize("PATIENT", "DOCTOR", "ASHA", "ADMIN"), validate(listConsultationsValidator), listConsultations);
router.get("/:id", authenticate, authorize("PATIENT", "DOCTOR", "ASHA", "ADMIN"), validate(consultationParam), getConsultationById);
router.patch("/:id/status", authenticate, authorize("PATIENT", "DOCTOR", "ASHA", "ADMIN"), validate(updateStatusValidator), updateStatus);
router.patch("/:id/accept", authenticate, authorize("DOCTOR"), validate(acceptConsultationValidator), acceptConsultation);
router.patch("/:id/complete", authenticate, authorize("DOCTOR"), validate(completeConsultationValidator), completeConsultation);
router.patch("/:id/assign-doctor", authenticate, authorize("PATIENT", "ASHA", "ADMIN"), validate(assignDoctorValidator), assignDoctor);

module.exports = router;
