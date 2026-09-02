const { query, param } = require("express-validator");

const paginationQuery = [
    query("page")
        .optional()
        .isInt({ min: 1 }).withMessage("page must be a positive integer")
        .toInt(),
    query("limit")
        .optional()
        .isInt({ min: 1, max: 100 }).withMessage("limit must be between 1 and 100")
        .toInt(),
    query("search")
        .optional()
        .trim()
        .isLength({ max: 100 }).withMessage("search must be at most 100 characters")
];

const uuidParam = (name = "id") => [
    param(name)
        .isUUID().withMessage(`${name} must be a valid UUID`)
];

module.exports = { paginationQuery, uuidParam };
