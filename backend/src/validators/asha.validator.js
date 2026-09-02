const { body } = require("express-validator");
const { paginationQuery } = require("./common.validator");

const ashaFields = [
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
    createAshaWorker: ashaFields,
    updateAshaWorker: ashaFields,
    listAshaWorkers: paginationQuery
};
