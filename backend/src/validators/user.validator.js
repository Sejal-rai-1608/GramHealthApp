const { query } = require("express-validator");
const { paginationQuery } = require("./common.validator");

const listUsers = [
    ...paginationQuery,
    query("role")
        .optional()
        .isIn(["PATIENT", "DOCTOR", "ASHA", "ADMIN"]).withMessage("Invalid role filter")
];

module.exports = { listUsers };
