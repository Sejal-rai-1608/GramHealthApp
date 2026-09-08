const jwt = require("jsonwebtoken");
const prisma = require("../config/prisma");

const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        const hasAuthHeader = !!authHeader;
        
        console.log(`[AuthMiddleware] POST ${req.path} - Has Auth Header: ${hasAuthHeader}`);

        if (!authHeader) {
            return res.status(401).json({
                success: false,
                message: "Authorization header is required"
            });
        }

        if (!authHeader.startsWith("Bearer ")) {
            console.log(`[AuthMiddleware] Failure: Invalid format`);
            return res.status(401).json({
                success: false,
                message: "Invalid authorization format"
            });
        }

        const token = authHeader.split(" ")[1];

        // Ensure we use the exact same secret as login
        const secret = process.env.JWT_SECRET || "gramhealth-fallback-secret-key";

        const decoded = jwt.verify(token, secret);
        
        console.log(`[AuthMiddleware] Token decoded for User ID: ${decoded.userId}`);

        if (!decoded.userId) {
            console.log(`[AuthMiddleware] Failure: Missing userId in token payload`);
            return res.status(401).json({
                success: false,
                message: "Invalid or expired token"
            });
        }

        const user = await prisma.user.findUnique({
            where: { id: decoded.userId },
            select: { id: true, name: true, phone: true, email: true, role: true }
        });

        if (!user) {
            console.log(`[AuthMiddleware] Failure: User not found in DB`);
            return res.status(401).json({
                success: false,
                message: "Invalid or expired token"
            });
        }

        req.user = {
            userId: user.id,
            role: user.role,
            name: user.name,
            phone: user.phone,
            email: user.email
        };

        next();

    } catch (error) {
        console.log(`[AuthMiddleware] Verification Failed: ${error.name} - ${error.message}`);
        if (
            error.name === "JsonWebTokenError" ||
            error.name === "TokenExpiredError" ||
            error.name === "NotBeforeError"
        ) {
            return res.status(401).json({
                success: false,
                message: "Invalid or expired token"
            });
        }

        next(error);
    }
};

const authorize = (...allowedRoles) => {
    return (req, res, next) => {

        if (!req.user) {
            return res.status(401).json({
                success: false,
                message: "Authentication required"
            });
        }

        if (!allowedRoles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: "You do not have permission to access this resource"
            });
        }

        next();
    };
};

module.exports = {
    authenticate,
    authorize
};
