const prisma = require("../config/prisma");
const ApiError = require("./ApiError");

const PROFILE_NOT_FOUND_MESSAGES = {
    PATIENT: "Patient profile not found. Please create your patient profile first.",
    DOCTOR: "Doctor profile not found. Please create your doctor profile first.",
    ASHA: "ASHA worker profile not found. Please create your ASHA worker profile first."
};

const getProfileIdForRole = async (role, userId) => {
    switch (role) {
        case "PATIENT":
            return (await prisma.patient.findUnique({ where: { userId } }))?.id || null;
        case "DOCTOR":
            return (await prisma.doctor.findUnique({ where: { userId } }))?.id || null;
        case "ASHA":
            return (await prisma.ashaWorker.findUnique({ where: { userId } }))?.id || null;
        default:
            return null;
    }
};

const requireProfile = async (role, userId) => {
    const profileId = await getProfileIdForRole(role, userId);

    if (!profileId) {
        throw new ApiError(
            PROFILE_NOT_FOUND_MESSAGES[role] || "Profile not found",
            404,
            "PROFILE_NOT_FOUND"
        );
    }

    return profileId;
};

module.exports = {
    getProfileIdForRole,
    requireProfile,
    PROFILE_NOT_FOUND_MESSAGES
};
