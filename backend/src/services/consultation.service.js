const prisma = require("../config/prisma");
const ApiError = require("../utils/ApiError");
const { getPagination, buildMeta } = require("../utils/pagination");
const { canTransitionConsultationStatus } = require("../utils/consultationStatus");
const { CONSULTATION_RISK_LEVELS } = require("../constants/consultation");
const { getProfileIdForRole, requireProfile } = require("../utils/profile");

const USER_SELECT = { id: true, name: true, phone: true, email: true };

const CONSULTATION_INCLUDE = {
    patient: { include: { user: { select: USER_SELECT } } },
    doctor: { include: { user: { select: USER_SELECT } } },
    ashaWorker: { include: { user: { select: USER_SELECT } } }
};

const getConsultationOr404 = async (id) => {
    const consultation = await prisma.consultation.findUnique({ where: { id } });

    if (!consultation) {
        throw new ApiError("Consultation not found", 404, "NOT_FOUND");
    }

    return consultation;
};

const assertValidRiskLevel = (riskLevel) => {
    if (riskLevel !== undefined && !CONSULTATION_RISK_LEVELS.includes(riskLevel)) {
        throw new ApiError(
            `riskLevel must be one of: ${CONSULTATION_RISK_LEVELS.join(", ")}`,
            400,
            "VALIDATION_ERROR"
        );
    }
};

const createConsultation = async (user, data) => {
    let patientId = null;
    let ashaWorkerId = null;

    assertValidRiskLevel(data.riskLevel);

    if (user.role === "PATIENT") {
        patientId = await requireProfile("PATIENT", user.userId);
    } else if (user.role === "ASHA") {
        ashaWorkerId = await requireProfile("ASHA", user.userId);

        if (!data.patientId) {
            throw new ApiError("patientId is required", 400, "VALIDATION_ERROR");
        }

        const patient = await prisma.patient.findUnique({ where: { id: data.patientId } });

        if (!patient) {
            throw new ApiError("Patient not found", 404, "NOT_FOUND");
        }

        patientId = patient.id;
    } else {
        throw new ApiError(
            "You do not have permission to create consultations",
            403,
            "FORBIDDEN"
        );
    }

    return prisma.consultation.create({
        data: {
            patientId,
            ashaWorkerId,
            // If the patient selected a specific doctor, assign them directly.
            // Otherwise the consultation goes into the open pool (doctorId = null).
            ...(data.doctorId ? { doctorId: data.doctorId } : {}),
            type: data.type,
            symptoms: data.symptoms,
            notes: data.notes,
            status: "PENDING",
            ...(data.riskLevel !== undefined ? { riskLevel: data.riskLevel } : {})
        },
        include: CONSULTATION_INCLUDE
    });
};

const getConsultationById = async (id, user) => {
    const consultation = await prisma.consultation.findUnique({
        where: { id },
        include: CONSULTATION_INCLUDE
    });

    if (!consultation) {
        throw new ApiError("Consultation not found", 404, "NOT_FOUND");
    }

    if (user.role !== "ADMIN") {
        const profileId = await getProfileIdForRole(user.role, user.userId);

        const hasAccess =
            (user.role === "PATIENT" && consultation.patientId === profileId) ||
            (user.role === "DOCTOR" && consultation.doctorId === profileId) ||
            (user.role === "ASHA" && consultation.ashaWorkerId === profileId);

        if (!hasAccess) {
            throw new ApiError(
                "You do not have permission to access this consultation",
                403,
                "FORBIDDEN"
            );
        }
    }

    return consultation;
};

const listConsultations = async (user, query = {}) => {
    const { page, limit, skip, take } = getPagination(query);
    const where = {};

    if (query.status) {
        where.status = query.status;
    }

    if (query.type) {
        where.type = query.type;
    }

    if (user.role !== "ADMIN") {
        const profileId = await getProfileIdForRole(user.role, user.userId);

        if (!profileId) {
            return { items: [], meta: buildMeta(0, page, limit) };
        }

        if (user.role === "PATIENT") {
            where.patientId = profileId;
        } else if (user.role === "DOCTOR") {
            // Doctors see:
            //  a) Consultations already assigned to them (any status)
            //  b) PENDING consultations with no assigned doctor yet (open pool)
            where.OR = [
                { doctorId: profileId },
                { doctorId: null, status: "PENDING" }
            ];
        } else if (user.role === "ASHA") {
            where.ashaWorkerId = profileId;
        }
    }

    const [total, items] = await Promise.all([
        prisma.consultation.count({ where }),
        prisma.consultation.findMany({
            where,
            include: CONSULTATION_INCLUDE,
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    return { items, meta: buildMeta(total, page, limit) };
};

const updateStatus = async (id, user, { status, notes, riskLevel }) => {
    const consultation = await getConsultationOr404(id);

    const current = consultation.status;

    if (current === status) {
        if (user.role === "DOCTOR" && notes !== undefined) {
            const profileId = await getProfileIdForRole("DOCTOR", user.userId);

            if (consultation.doctorId === profileId) {
                return prisma.consultation.update({
                    where: { id },
                    data: { notes },
                    include: CONSULTATION_INCLUDE
                });
            }
        }

        throw new ApiError(
            `Consultation is already ${current}`,
            400,
            "INVALID_TRANSITION"
        );
    }

    const transition = `${current}->${status}`;

    if (!canTransitionConsultationStatus(current, status)) {
        throw new ApiError(
            `Cannot change consultation status from ${current} to ${status}`,
            400,
            "INVALID_TRANSITION"
        );
    }

    if (transition === "PENDING->ACTIVE") {
        if (user.role !== "DOCTOR") {
            throw new ApiError(
                "Only a doctor can accept a consultation",
                403,
                "FORBIDDEN"
            );
        }

        const profileId = await requireProfile("DOCTOR", user.userId);

        if (consultation.doctorId !== profileId) {
            throw new ApiError(
                "Only the assigned doctor can accept this consultation",
                403,
                "FORBIDDEN"
            );
        }

        const data = { status: "ACTIVE" };

        if (notes !== undefined) {
            data.notes = notes;
        }

        return prisma.consultation.update({
            where: { id },
            data,
            include: CONSULTATION_INCLUDE
        });
    }

    if (transition === "ACTIVE->COMPLETED") {
        if (user.role !== "DOCTOR") {
            throw new ApiError(
                "Only the assigned doctor can complete a consultation",
                403,
                "FORBIDDEN"
            );
        }

        const profileId = await requireProfile("DOCTOR", user.userId);

        if (consultation.doctorId !== profileId) {
            throw new ApiError(
                "Only the assigned doctor can complete a consultation",
                403,
                "FORBIDDEN"
            );
        }

        assertValidRiskLevel(riskLevel);

        const data = { status: "COMPLETED" };

        if (notes !== undefined) {
            data.notes = notes;
        }

        if (riskLevel !== undefined) {
            data.riskLevel = riskLevel;
        }

        return prisma.consultation.update({
            where: { id },
            data,
            include: CONSULTATION_INCLUDE
        });
    }

    if (transition === "PENDING->CANCELLED") {
        const profileId = await getProfileIdForRole(user.role, user.userId);

        const canCancel =
            user.role === "ADMIN" ||
            (user.role === "PATIENT" && consultation.patientId === profileId) ||
            (user.role === "ASHA" && consultation.ashaWorkerId === profileId);

        if (!canCancel) {
            throw new ApiError(
                "You do not have permission to cancel this consultation",
                403,
                "FORBIDDEN"
            );
        }

        return prisma.consultation.update({
            where: { id },
            data: { status: "CANCELLED" },
            include: CONSULTATION_INCLUDE
        });
    }

    if (transition === "ACTIVE->CANCELLED") {
        const profileId = await getProfileIdForRole(user.role, user.userId);

        const canCancel =
            user.role === "ADMIN" ||
            (user.role === "PATIENT" && consultation.patientId === profileId);

        if (!canCancel) {
            throw new ApiError(
                "You do not have permission to cancel this consultation",
                403,
                "FORBIDDEN"
            );
        }

        return prisma.consultation.update({
            where: { id },
            data: { status: "CANCELLED" },
            include: CONSULTATION_INCLUDE
        });
    }

    throw new ApiError(
        `Cannot change consultation status from ${current} to ${status}`,
        400,
        "INVALID_TRANSITION"
    );
};

const acceptConsultation = async (id, user, { notes } = {}) => {
    const consultation = await getConsultationOr404(id);

    if (user.role !== "DOCTOR") {
        throw new ApiError(
            "Only a doctor can accept a consultation",
            403,
            "FORBIDDEN"
        );
    }

    if (consultation.status !== "PENDING") {
        throw new ApiError(
            `Cannot accept a consultation that is ${consultation.status.toLowerCase()}`,
            400,
            "INVALID_STATE"
        );
    }

    const profileId = await requireProfile("DOCTOR", user.userId);

    // If a specific doctor was already assigned, only that doctor can accept.
    // If no doctor was assigned yet (patient posted to any available doctor),
    // auto-assign this doctor and accept.
    if (consultation.doctorId !== null && consultation.doctorId !== profileId) {
        throw new ApiError(
            "Only the assigned doctor can accept this consultation",
            403,
            "FORBIDDEN"
        );
    }

    const data = { status: "ACTIVE", doctorId: profileId };

    if (notes !== undefined) {
        data.notes = notes;
    }

    return prisma.consultation.update({
        where: { id },
        data,
        include: CONSULTATION_INCLUDE
    });
};

const completeConsultation = async (id, user, { notes, riskLevel } = {}) => {
    const consultation = await getConsultationOr404(id);

    if (user.role !== "DOCTOR") {
        throw new ApiError(
            "Only the assigned doctor can complete a consultation",
            403,
            "FORBIDDEN"
        );
    }

    if (consultation.status !== "ACTIVE") {
        throw new ApiError(
            `Cannot complete a consultation that is ${consultation.status.toLowerCase()}`,
            400,
            "INVALID_STATE"
        );
    }

    const profileId = await requireProfile("DOCTOR", user.userId);

    if (consultation.doctorId !== profileId) {
        throw new ApiError(
            "Only the assigned doctor can complete a consultation",
            403,
            "FORBIDDEN"
        );
    }

    assertValidRiskLevel(riskLevel);

    const data = { status: "COMPLETED" };

    if (notes !== undefined) {
        data.notes = notes;
    }

    if (riskLevel !== undefined) {
        data.riskLevel = riskLevel;
    }

    return prisma.consultation.update({
        where: { id },
        data,
        include: CONSULTATION_INCLUDE
    });
};

const assignDoctor = async (id, user, { doctorId }) => {
    const consultation = await getConsultationOr404(id);

    if (consultation.status === "COMPLETED" || consultation.status === "CANCELLED") {
        throw new ApiError(
            `Cannot assign a doctor to a ${consultation.status.toLowerCase()} consultation`,
            400,
            "INVALID_STATE"
        );
    }

    const doctor = await prisma.doctor.findUnique({
        where: { id: doctorId },
        include: { user: { select: USER_SELECT } }
    });

    if (!doctor) {
        throw new ApiError("Doctor not found", 404, "NOT_FOUND");
    }

    if (user.role !== "ADMIN") {
        const profileId = await getProfileIdForRole(user.role, user.userId);

        const isCreator =
            (user.role === "PATIENT" && consultation.patientId === profileId) ||
            (user.role === "ASHA" && consultation.ashaWorkerId === profileId);

        if (!isCreator) {
            throw new ApiError(
                "You do not have permission to assign a doctor",
                403,
                "FORBIDDEN"
            );
        }
    }

    return prisma.consultation.update({
        where: { id },
        data: { doctorId },
        include: CONSULTATION_INCLUDE
    });
};

module.exports = {
    createConsultation,
    getConsultationById,
    listConsultations,
    updateStatus,
    acceptConsultation,
    completeConsultation,
    assignDoctor
};
