const { body, query } = require("express-validator");
const { paginationQuery, uuidParam } = require("./common.validator");

const createMedicalRecord = [
    body("consultationId")
        .isUUID().withMessage("consultationId must be a valid UUID"),
    body("diagnosis")
        .optional({ values: "falsy" })
        .trim()
        .isLength({ max: 2000 }).withMessage("diagnosis must be at most 2000 characters"),
    body("clinicalNotes")
        .optional({ values: "falsy" })
        .trim()
        .isLength({ max: 5000 }).withMessage("clinicalNotes must be at most 5000 characters")
];

const medicalRecordParam = uuidParam("id");

const listMedicalRecords = [
    ...paginationQuery,
    query("patientId")
        .optional()
        .isUUID().withMessage("patientId must be a valid UUID")
];

module.exports = {
    createMedicalRecord,
    medicalRecordParam,
    listMedicalRecords
};
