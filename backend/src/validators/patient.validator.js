const { body } = require("express-validator");
const { paginationQuery } = require("./common.validator");

const patientFields = [
    body("dateOfBirth")
        .optional({ checkFalsy: true })
        .isISO8601().withMessage("dateOfBirth must be a valid ISO date")
        .toDate(),
    body("gender")
        .optional({ checkFalsy: true })
        .trim()
        .isLength({ max: 20 }).withMessage("gender must be at most 20 characters"),
    body("village")
        .optional({ checkFalsy: true })
        .trim()
        .isLength({ max: 150 }).withMessage("village must be at most 150 characters"),
    body("district")
        .optional({ checkFalsy: true })
        .trim()
        .isLength({ max: 150 }).withMessage("district must be at most 150 characters"),
    body("state")
        .optional({ checkFalsy: true })
        .trim()
        .isLength({ max: 150 }).withMessage("state must be at most 150 characters")
];

module.exports = {
    createPatient: patientFields,
    updatePatient: patientFields,
    listPatients: paginationQuery
};
