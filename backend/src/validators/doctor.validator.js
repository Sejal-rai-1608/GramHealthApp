const { body, query } = require("express-validator");
const { paginationQuery } = require("./common.validator");

const doctorFields = [
    body("specialization")
        .optional({ checkFalsy: true })
        .trim()
        .isLength({ max: 150 }).withMessage("specialization must be at most 150 characters"),
    body("registrationNumber")
        .optional({ checkFalsy: true })
        .trim()
        .isLength({ max: 100 }).withMessage("registrationNumber must be at most 100 characters"),
    body("hospitalName")
        .optional({ checkFalsy: true })
        .trim()
        .isLength({ max: 200 }).withMessage("hospitalName must be at most 200 characters")
];

const listDoctors = [
    ...paginationQuery,
    query("specialization")
        .optional()
        .trim()
        .isLength({ max: 150 }).withMessage("specialization must be at most 150 characters"),
    query("hospitalName")
        .optional()
        .trim()
        .isLength({ max: 200 }).withMessage("hospitalName must be at most 200 characters")
];

module.exports = {
    createDoctor: doctorFields,
    updateDoctor: doctorFields,
    listDoctors
};
