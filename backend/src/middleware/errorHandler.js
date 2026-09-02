const ApiError = require("../utils/ApiError");

const prismaErrorToApiError = (err) => {
    switch (err.code) {
        case "P2002":
            return new ApiError(
                "A record with the same unique value already exists",
                409,
                "DUPLICATE_ENTRY"
            );
        case "P2025":
            return new ApiError("Record not found", 404, "NOT_FOUND");
        case "P2003":
            return new ApiError("Invalid reference provided", 400, "INVALID_REFERENCE");
        case "P2007":
            return new ApiError("Invalid value provided", 400, "INVALID_VALUE");
        default:
            return new ApiError("Database error", 500, "DATABASE_ERROR");
    }
};

const errorHandler = (err, req, res, next) => {
    if (res.headersSent) {
        return next(err);
    }

    let error = err instanceof ApiError ? err : null;

    if (!error && err && err.name === "PrismaClientKnownRequestError") {
        error = prismaErrorToApiError(err);
    }

    if (!error && err && err.name === "PrismaClientValidationError") {
        error = new ApiError("Invalid data provided", 400, "VALIDATION_ERROR");
    }

    if (!error && err && typeof err.status === "number" && err.status >= 400 && err.status < 500) {
        const status = err.status === 413 ? 413 : 400;
        error = new ApiError(
            status === 413 ? "Request body too large" : "Invalid request body",
            status,
            "BAD_REQUEST"
        );
    }

    if (!error) {
        console.error("Unhandled error:", err);
        error = new ApiError("Internal server error", 500, "INTERNAL_ERROR");
    } else if (error.statusCode >= 500) {
        console.error(`${error.statusCode} ${error.message}:`, err);
    } else {
        console.warn(`${error.statusCode} ${error.code}: ${error.message}`);
    }

    const payload = {
        success: false,
        message: error.message,
        code: error.code
    };

    if (process.env.NODE_ENV !== "production" && err && err.stack) {
        payload.stack = err.stack;
    }

    res.status(error.statusCode).json(payload);
};

module.exports = { errorHandler };
