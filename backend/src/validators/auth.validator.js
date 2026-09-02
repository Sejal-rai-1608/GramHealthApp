const { body } = require("express-validator");

const register = [
    body("name")
        .trim()
        .notEmpty().withMessage("Name is required")
        .isLength({ max: 150 }).withMessage("Name must be at most 150 characters"),
    body("phone")
        .trim()
        .notEmpty().withMessage("Phone is required")
        .matches(/^[0-9+\-\s]{10,20}$/).withMessage("Phone must be a valid 10-20 digit number"),
    body("email")
        .trim()
        .notEmpty().withMessage("Email is required")
        .isEmail().withMessage("Email must be valid")
        .isLength({ max: 255 }).withMessage("Email must be at most 255 characters"),
    body("password")
        .isLength({ min: 8 }).withMessage("Password must be at least 8 characters")
        .isLength({ max: 128 }).withMessage("Password must be at most 128 characters"),
    body("role")
        .optional()
        .isIn(["PATIENT", "DOCTOR", "ASHA", "ADMIN"]).withMessage("Invalid role")
];

module.exports = { register };
