const { body, query } = require("express-validator");
const { paginationQuery, uuidParam } = require("./common.validator");
const { validateMedicines } = require("./prescription.validator");
const {
    CONSULTATION_TYPES,
    CONSULTATION_STATUSES,
    CONSULTATION_RISK_LEVELS
} = require("../constants/consultation");

const riskLevelValidator = body("riskLevel")
    .optional({ values: "falsy" })
    .isIn(CONSULTATION_RISK_LEVELS)
    .withMessage(`riskLevel must be one of: ${CONSULTATION_RISK_LEVELS.join(", ")}`);

const createConsultation = [
    body("reason")
        .trim()
        .isLength({ min: 1, max: 200 })
        .withMessage("reason is required and must be at most 200 characters"),
    body("patientId")
        .optional({ values: "falsy" })
        .isUUID().withMessage("patientId must be a valid UUID"),
    body("doctorId")
        .optional({ values: "falsy" })
        .isUUID().withMessage("doctorId must be a valid UUID"),
    body("type")
        .isIn(CONSULTATION_TYPES).withMessage(`type must be one of: ${CONSULTATION_TYPES.join(", ")}`),
    body("symptoms")
        .optional({ values: "falsy" })
        .trim()
        .isLength({ max: 2000 }).withMessage("symptoms must be at most 2000 characters"),
    body("notes")
        .optional({ values: "falsy" })
        .trim()
        .isLength({ max: 5000 }).withMessage("notes must be at most 5000 characters"),
    body("scheduledAt")
        .optional({ values: "falsy" })
        .isISO8601().withMessage("scheduledAt must be a valid ISO-8601 date")
        .toDate(),
    body("voiceNoteUrl")
        .optional({ values: "falsy" })
        .isString().withMessage("voiceNoteUrl must be a string")
        .isLength({ max: 20000000 }).withMessage("voiceNoteUrl is too large"),
    body("voiceNoteDuration")
        .optional({ values: "falsy" })
        .isInt({ min: 0, max: 86400 }).withMessage("voiceNoteDuration must be a valid duration")
        .toInt(),
    riskLevelValidator
];

const updateStatus = [
    ...uuidParam("id"),
    body("status")
        .isIn(CONSULTATION_STATUSES).withMessage(`status must be one of: ${CONSULTATION_STATUSES.join(", ")}`),
    body("notes")
        .optional({ values: "falsy" })
        .trim()
        .isLength({ max: 5000 }).withMessage("notes must be at most 5000 characters"),
    riskLevelValidator
];

const acceptConsultation = [
    ...uuidParam("id"),
    body("notes")
        .optional({ values: "falsy" })
        .trim()
        .isLength({ max: 5000 }).withMessage("notes must be at most 5000 characters")
];

const completeConsultation = [
    ...uuidParam("id"),
    body("symptoms")
        .optional({ values: "falsy" })
        .trim()
        .isLength({ max: 2000 }).withMessage("symptoms must be at most 2000 characters"),
    body("notes")
        .optional({ values: "falsy" })
        .trim()
        .isLength({ max: 5000 }).withMessage("notes must be at most 5000 characters"),
    body("medicines")
        .optional({ values: "falsy" })
        .custom(validateMedicines),
    body("prescriptionInstructions")
        .optional({ values: "falsy" })
        .trim()
        .isLength({ max: 5000 }).withMessage("prescriptionInstructions must be at most 5000 characters"),
    body("followUpDate")
        .optional({ values: "falsy" })
        .isISO8601().withMessage("followUpDate must be a valid ISO-8601 date")
        .toDate(),
    riskLevelValidator
];

const assignDoctor = [
    ...uuidParam("id"),
    body("doctorId")
        .isUUID().withMessage("doctorId must be a valid UUID")
];

const consultationParam = uuidParam("id");

const listConsultations = [
    ...paginationQuery,
    query("status")
        .optional()
        .isIn(CONSULTATION_STATUSES).withMessage(`status must be one of: ${CONSULTATION_STATUSES.join(", ")}`),
    query("type")
        .optional()
        .isIn(CONSULTATION_TYPES).withMessage(`type must be one of: ${CONSULTATION_TYPES.join(", ")}`)
];

module.exports = {
    createConsultation,
    updateStatus,
    acceptConsultation,
    completeConsultation,
    assignDoctor,
    consultationParam,
    listConsultations
};
