const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const prisma = require("../config/prisma");
const ApiError = require("../utils/ApiError");
const { sendOtpEmail } = require("./email.service");

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

// ── Forgot Password (Step 1: Send OTP) ────────────────────────────────────

const forgotPassword = async ({ emailOrPhone }) => {
    const identifier = (emailOrPhone || "").trim();
    if (!identifier) {
        throw new ApiError("Email or phone is required", 400, "INVALID_INPUT");
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
        // For security, don't reveal whether user exists
        return { message: "If the email/phone is registered, a reset code has been sent" };
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Store OTP in user record (you may want a separate OTP table in production)
    await prisma.user.update({
        where: { id: user.id },
        data: {
            resetOtp: otp,
            resetOtpExpiry: otpExpiry
        }
    });

    // Send OTP via email if user has email
    if (user.email) {
      try {
        const emailResult = await sendOtpEmail(user.email, otp, user.name || "User");
        if (emailResult.success) {
          console.log(`[AuthService] OTP email sent successfully to ${user.email}: ${emailResult.messageId || 'dev mode'}`);
        } else {
          console.error(`[AuthService] OTP email failed to send to ${user.email}:`, emailResult.error);
          console.log(`[AuthService] OTP for ${user.email} (check logs): ${otp}`);
        }
      } catch (emailError) {
        console.error("[AuthService] Failed to send OTP email:", emailError);
        console.log(`[AuthService] OTP for ${user.email} (check logs): ${otp}`);
      }
    } else {
      // For phone numbers, log OTP (integrate SMS service in production)
      console.log(`[OTP] Reset code for ${user.phone}: ${otp}`);
    }

    return { message: "If the email/phone is registered, a reset code has been sent" };
};

// ── Reset Password with Token (Step 2: Verify OTP + New Password) ────────

const resetPasswordWithToken = async ({ emailOrPhone, otp, newPassword }) => {
    const identifier = (emailOrPhone || "").trim();
    if (!identifier || !otp || !newPassword) {
        throw new ApiError("Email/phone, OTP and new password are required", 400, "INVALID_INPUT");
    }

    if (otp.length !== 6) {
        throw new ApiError("Invalid OTP format", 400, "INVALID_OTP");
    }

    if (newPassword.length < 6) {
        throw new ApiError("New password must be at least 6 characters", 400, "INVALID_PASSWORD");
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

    // Verify OTP
    if (!user.resetOtp || user.resetOtp !== otp) {
        throw new ApiError("Invalid or expired reset code", 400, "INVALID_OTP");
    }

    if (!user.resetOtpExpiry || new Date() > user.resetOtpExpiry) {
        throw new ApiError("Reset code has expired", 400, "OTP_EXPIRED");
    }

    if (newPassword.length < 6) {
        throw new ApiError("New password must be at least 6 characters", 400, "INVALID_PASSWORD");
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);

    await prisma.user.update({
        where: { id: user.id },
        data: {
            passwordHash: await bcrypt.hash(newPassword, 12),
            resetOtp: null,
            resetOtpExpiry: null
        }
    });

    return { message: "Password updated successfully" };
};

module.exports = {
    registerUser,
    loginUser,
    resetPassword,
    forgotPassword,
    resetPasswordWithToken
};