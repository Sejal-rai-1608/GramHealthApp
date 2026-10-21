const {
    validationResult,
    matchedData
} = require("express-validator");

const validate = (rules) => [
    ...rules,
    (req, res, next) => {
        const errors = validationResult(req);

        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: "Validation failed",
                code: "VALIDATION_ERROR",
                errors: errors.array({ onlyFirstError: true }).map((e) => ({
                    field: e.path,
                    message: e.msg
                }))
            });
        }

        next();
    }
];

module.exports = {
    validate,
    matchedData
};
