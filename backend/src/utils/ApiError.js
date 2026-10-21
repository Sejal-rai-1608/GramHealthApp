class ApiError extends Error {
    constructor(message, statusCode, code = "ERROR", details) {
        super(message);
        this.name = "ApiError";
        this.statusCode = statusCode;
        this.code = code;
        this.details = details;
    }
}

module.exports = ApiError;
