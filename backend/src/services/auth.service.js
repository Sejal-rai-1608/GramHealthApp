const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const prisma = require("../config/prisma");
const ApiError = require("../utils/ApiError");

const registerUser = async ({ name, email, phone, password, role, address, latitude, longitude }) => {
    const existingUser = await prisma.user.findFirst({
        where: {
            OR: [
                { email },
                ...(phone ? [{ phone }] : [])
            ]
        }
    });

    if (existingUser) {
        throw new ApiError(
            "User with this email or phone already exists",
            409,
            "DUPLICATE_ENTRY"
        );
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    const user = await prisma.user.create({
        data: {
            name,
            email,
            phone,
            passwordHash: hashedPassword,
            role: role || "PATIENT"
        },
        select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            role: true,
            createdAt: true
        }
    });

    // Auto-create role-specific profile so downstream services work immediately.
    // ADMIN has no sub-table – skip. For all other roles we must succeed.
    const effectiveRole = (role || "PATIENT").toUpperCase();
    if (effectiveRole === "PATIENT") {
        await prisma.patient.create({ data: { userId: user.id } });
    } else if (effectiveRole === "DOCTOR") {
        await prisma.doctor.create({ data: { userId: user.id } });
    } else if (effectiveRole === "ASHA") {
        await prisma.ashaWorker.create({ data: { userId: user.id } });
    } else if (effectiveRole === "PHARMACY") {
        await prisma.pharmacy.create({ 
            data: { 
                userId: user.id, 
                name: `${name}'s Pharmacy`,
                address: address || null,
                latitude: latitude || 0,
                longitude: longitude || 0
            } 
        });
    }
    // ADMIN: no sub-table needed

    return user;
};

const loginUser = async ({ email, password }) => {
    const identifier = email ? email.trim() : "";

    const user = await prisma.user.findFirst({
        where: {
            OR: [
                { email: { equals: identifier, mode: "insensitive" } },
                { phone: identifier }
            ]
        }
    });

    if (!user) {
        throw new ApiError("Invalid email/phone or password", 401, "INVALID_CREDENTIALS");
    }

    const passwordMatch = await bcrypt.compare(
        password,
        user.passwordHash
    );

    if (!passwordMatch) {
        throw new ApiError("Invalid email or password", 401, "INVALID_CREDENTIALS");
    }

    const token = jwt.sign(
        {
            userId: user.id,
            role: user.role
        },
        process.env.JWT_SECRET || "gramhealth-fallback-secret-key",
        {
            expiresIn: "3650d"
        }
    );

    return {
        token,
        user: {
            id: user.id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            role: user.role
        }
    };
};

const resetPassword = async ({ email, phone, newPassword }) => {
    const identifier = (email || phone || "").trim();
    if (!identifier || !newPassword) {
        throw new ApiError("Email/phone and new password are required", 400, "INVALID_INPUT");
    }

    const user = await prisma.user.findFirst({
        where: {
            OR: [
                { email: { equals: identifier, mode: "insensitive" } },
                { phone: identifier }
            ]
        }
    });

    if (!user) {
        throw new ApiError("User with this email or phone was not found", 404, "USER_NOT_FOUND");
    }

    if (newPassword.length < 6) {
        throw new ApiError("New password must be at least 6 characters", 400, "INVALID_PASSWORD");
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);

    await prisma.user.update({
        where: { id: user.id },
        data: { passwordHash: hashedPassword }
    });

    return { message: "Password updated successfully" };
};

module.exports = {
    registerUser,
    loginUser,
    resetPassword
};