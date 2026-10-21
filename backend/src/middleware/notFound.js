const ApiError = require("../utils/ApiError");

const notFound = (req, res, next) => {
    next(new ApiError(
        `Route ${req.method} ${req.originalUrl} not found`,
        404,
        "NOT_FOUND"
    ));
};

module.exports = { notFound };
