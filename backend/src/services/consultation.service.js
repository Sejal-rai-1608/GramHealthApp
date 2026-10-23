const prisma = require("../config/prisma");
const ApiError = require("../utils/ApiError");
const { getPagination, buildMeta } = require("../utils/pagination");
const { canTransitionConsultationStatus } = require("../utils/consultationStatus");
const { CONSULTATION_RISK_LEVELS } = require("../constants/consultation");
const { getProfileIdForRole, requireProfile } = require("../utils/profile");
const aiService = require("./ai.service");

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

    if (data.scheduledAt !== undefined) {
        const scheduledAt = new Date(data.scheduledAt);

        if (Number.isNaN(scheduledAt.getTime())) {
            throw new ApiError("scheduledAt must be a valid date", 400, "VALIDATION_ERROR");
        }

        if (scheduledAt.getTime() <= Date.now()) {
            throw new ApiError("scheduledAt must be in the future", 400, "VALIDATION_ERROR");
        }
    }

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

    if (data.doctorId) {
        const doctor = await prisma.doctor.findUnique({
            where: { id: data.doctorId }
        });

        if (!doctor) {
            throw new ApiError("Doctor not found", 404, "NOT_FOUND");
        }

        if (data.scheduledAt) {
            const conflictingAppointment = await prisma.consultation.findFirst({
                where: {
                    doctorId: data.doctorId,
                    scheduledAt: data.scheduledAt,
                    status: { in: ["PENDING", "ACTIVE"] }
                }
            });

            if (conflictingAppointment) {
                throw new ApiError(
                    "The doctor already has an appointment at this time",
                    409,
                    "SCHEDULE_CONFLICT"
                );
            }
        }
    }

    const result = await prisma.consultation.create({
        data: {
            patientId,
            ashaWorkerId,
            // If the patient selected a specific doctor, assign them directly.
            // Otherwise the consultation goes into the open pool (doctorId = null).
            ...(data.doctorId ? { doctorId: data.doctorId } : {}),
            type: data.type,
            reason: data.reason,
            symptoms: data.symptoms,
            notes: data.notes,
            scheduledAt: data.scheduledAt,
            voiceNoteUrl: data.voiceNoteUrl,
            voiceNoteDuration: data.voiceNoteDuration,
            status: "PENDING",
            ...(data.riskLevel !== undefined ? { riskLevel: data.riskLevel } : {})
        },
        include: CONSULTATION_INCLUDE
    });

    if (result.symptoms || result.notes) {
        aiService.syncPatientRecord(
            result.patientId,
            result.id,
            "consultation",
            result.createdAt,
            `Reason: ${result.reason || 'None'}. Symptoms: ${result.symptoms || 'None'}. Notes: ${result.notes || 'None'}`,
            "GramHealth System"
        );
    }

    return result;
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
                const updated = await prisma.consultation.update({
                    where: { id },
                    data: { notes },
                    include: CONSULTATION_INCLUDE
                });
                
                aiService.syncPatientRecord(
                    updated.patientId,
                    updated.id,
                    "consultation",
                    updated.updatedAt,
                    `Status: ${updated.status}. Symptoms: ${updated.symptoms || 'None'}. Notes: ${updated.notes || 'None'}. Risk Level: ${updated.riskLevel || 'None'}`,
                    "GramHealth System"
                );
                
                return updated;
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

        const updated = await prisma.consultation.update({
            where: { id },
            data,
            include: CONSULTATION_INCLUDE
        });
        
        aiService.syncPatientRecord(
            updated.patientId,
            updated.id,
            "consultation",
            updated.updatedAt,
            `Status: ${updated.status}. Symptoms: ${updated.symptoms || 'None'}. Notes: ${updated.notes || 'None'}. Risk Level: ${updated.riskLevel || 'None'}`,
            "GramHealth System"
        );
        
        return updated;
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

        const updated = await prisma.consultation.update({
            where: { id },
            data,
            include: CONSULTATION_INCLUDE
        });
        
        aiService.syncPatientRecord(
            updated.patientId,
            updated.id,
            "consultation",
            updated.updatedAt,
            `Status: ${updated.status}. Symptoms: ${updated.symptoms || 'None'}. Notes: ${updated.notes || 'None'}. Risk Level: ${updated.riskLevel || 'None'}`,
            "GramHealth System"
        );
        
        return updated;
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

    if (consultation.status === "ACTIVE") {
        const profileId = await requireProfile("DOCTOR", user.userId);

        if (consultation.doctorId === profileId) {
            return prisma.consultation.findUnique({
                where: { id },
                include: CONSULTATION_INCLUDE
            });
        }
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

    if (consultation.scheduledAt) {
        const conflictingAppointment = await prisma.consultation.findFirst({
            where: {
                id: { not: id },
                doctorId: profileId,
                scheduledAt: consultation.scheduledAt,
                status: { in: ["PENDING", "ACTIVE"] }
            }
        });

        if (conflictingAppointment) {
            throw new ApiError(
                "You already have an appointment scheduled at this time",
                409,
                "SCHEDULE_CONFLICT"
            );
        }
    }

    const claimed = await prisma.consultation.updateMany({
        where: {
            id,
            status: "PENDING",
            ...(consultation.doctorId === null
                ? { doctorId: null }
                : { doctorId: profileId })
        },
        data
    });

    if (claimed.count === 0) {
        const latest = await prisma.consultation.findUnique({ where: { id } });

        if (latest?.status === "ACTIVE" && latest.doctorId === profileId) {
            return prisma.consultation.findUnique({
                where: { id },
                include: CONSULTATION_INCLUDE
            });
        }

        throw new ApiError(
            "This consultation was accepted by another doctor or is no longer pending",
            409,
            "CONSULTATION_ALREADY_CLAIMED"
        );
    }

    const updated = await prisma.consultation.findUnique({
        where: { id },
        include: CONSULTATION_INCLUDE
    });
    
    aiService.syncPatientRecord(
        updated.patientId,
        updated.id,
        "consultation",
        updated.updatedAt,
        `Status: ${updated.status}. Symptoms: ${updated.symptoms || 'None'}. Notes: ${updated.notes || 'None'}. Risk Level: ${updated.riskLevel || 'None'}`,
        "GramHealth System"
    );
    
    return updated;
};

const sanitizePrescriptionMedicines = (medicines) => medicines.map((medicine) => {
    const sanitized = {
        name: medicine.name.trim(),
        dosage: medicine.dosage.trim(),
        frequency: medicine.frequency.trim(),
        duration: medicine.duration.trim()
    };

    if (medicine.instructions !== undefined && medicine.instructions !== "") {
        sanitized.instructions = medicine.instructions.trim();
    }

    return sanitized;
});

const completeConsultation = async (
    id,
    user,
    {
        symptoms,
        notes,
        riskLevel,
        medicines,
        prescriptionInstructions,
        followUpDate
    } = {}
) => {
    const consultation = await getConsultationOr404(id);

    if (user.role !== "DOCTOR") {
        throw new ApiError(
            "Only the assigned doctor can complete a consultation",
            403,
            "FORBIDDEN"
        );
    }

    if (consultation.status !== "ACTIVE" && consultation.status !== "COMPLETED") {
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

    if (consultation.status === "COMPLETED") {
        return prisma.consultation.findUnique({
            where: { id },
            include: CONSULTATION_INCLUDE
        });
    }

    assertValidRiskLevel(riskLevel);

    const data = { status: "COMPLETED" };

    if (symptoms !== undefined) {
        data.symptoms = symptoms;
    }

    if (notes !== undefined) {
        data.notes = notes;
    }

    if (riskLevel !== undefined) {
        data.riskLevel = riskLevel;
    }

    const updated = await prisma.$transaction(async (tx) => {
        const completed = await tx.consultation.update({
            where: { id },
            data,
            include: CONSULTATION_INCLUDE
        });

        if (Array.isArray(medicines) && medicines.length > 0) {
            const existingPrescription = await tx.prescription.findFirst({
                where: { consultationId: id }
            });

            if (!existingPrescription) {
                await tx.prescription.create({
                    data: {
                        patientId: consultation.patientId,
                        consultationId: id,
                        doctorId: profileId,
                        medicines: sanitizePrescriptionMedicines(medicines),
                        instructions: prescriptionInstructions,
                        followUpDate
                    }
                });
            }
        }

        return completed;
    });
    
    aiService.syncPatientRecord(
        updated.patientId,
        updated.id,
        "consultation",
        updated.updatedAt,
        `Status: ${updated.status}. Reason: ${updated.reason || 'None'}. Symptoms: ${updated.symptoms || 'None'}. Notes: ${updated.notes || 'None'}. Risk Level: ${updated.riskLevel || 'None'}`,
        "GramHealth System"
    );
    
    return updated;
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

    if (consultation.scheduledAt) {
        const conflictingAppointment = await prisma.consultation.findFirst({
            where: {
                id: { not: id },
                doctorId,
                scheduledAt: consultation.scheduledAt,
                status: { in: ["PENDING", "ACTIVE"] }
            }
        });

        if (conflictingAppointment) {
            throw new ApiError(
                "The doctor already has an appointment at this time",
                409,
                "SCHEDULE_CONFLICT"
            );
        }
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

const addVoiceNote = async (id, user, { voiceNoteUrl, voiceNoteDuration }) => {
    const consultation = await getConsultationOr404(id);

    const profileId = await getProfileIdForRole(user.role, user.userId);

    const canModify =
        user.role === "ADMIN" ||
        (user.role === "PATIENT" && consultation.patientId === profileId) ||
        (user.role === "ASHA" && consultation.ashaWorkerId === profileId) ||
        (user.role === "DOCTOR" && consultation.doctorId === profileId);

    if (!canModify) {
        throw new ApiError(
            "You do not have permission to attach a voice note to this consultation",
            403,
            "FORBIDDEN"
        );
    }

    if (consultation.status === "COMPLETED" || consultation.status === "CANCELLED") {
        throw new ApiError(
            `Cannot add a voice note to a ${consultation.status.toLowerCase()} consultation`,
            400,
            "INVALID_STATE"
        );
    }

    return prisma.consultation.update({
        where: { id },
        data: { voiceNoteUrl, voiceNoteDuration },
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
    assignDoctor,
    addVoiceNote
};
