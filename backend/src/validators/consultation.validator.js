const { body, query } = require("express-validator");
const { paginationQuery, uuidParam } = require("./common.validator");
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
    body("notes")
        .optional({ values: "falsy" })
        .trim()
        .isLength({ max: 5000 }).withMessage("notes must be at most 5000 characters"),
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
