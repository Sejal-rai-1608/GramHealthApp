const prisma = require("../config/prisma");
const ApiError = require("../utils/ApiError");
const { getPagination, buildMeta } = require("../utils/pagination");
const { getProfileIdForRole, requireProfile } = require("../utils/profile");

const USER_SELECT = { id: true, name: true, phone: true, email: true };

const MEDICAL_RECORD_INCLUDE = {
    patient: { include: { user: { select: USER_SELECT } } },
    consultation: {
        include: {
            doctor: { include: { user: { select: USER_SELECT } } }
        }
    }
};

const createMedicalRecord = async (user, { consultationId, diagnosis, clinicalNotes }) => {
    const doctorProfileId = await requireProfile("DOCTOR", user.userId);

    const consultation = await prisma.consultation.findUnique({
        where: { id: consultationId }
    });

    if (!consultation) {
        throw new ApiError("Consultation not found", 404, "CONSULTATION_NOT_FOUND");
    }

    if (consultation.doctorId !== doctorProfileId) {
        throw new ApiError(
            "Only the assigned doctor can create a medical record for this consultation",
            403,
            "UNAUTHORIZED_ACCESS"
        );
    }

    if (consultation.status !== "ACTIVE") {
        throw new ApiError(
            `Medical records can only be created for active consultations (current status: ${consultation.status})`,
            400,
            "INVALID_CONSULTATION_STATE"
        );
    }

    const existing = await prisma.medicalRecord.findFirst({
        where: { consultationId }
    });

    if (existing) {
        throw new ApiError(
            "Medical record already exists for this consultation",
            409,
            "MEDICAL_RECORD_EXISTS"
        );
    }

    return prisma.medicalRecord.create({
        data: {
            patientId: consultation.patientId,
            consultationId,
            diagnosis,
            clinicalNotes
        },
        include: MEDICAL_RECORD_INCLUDE
    });
};

const listMyMedicalRecords = async (user, query = {}) => {
    const { page, limit, skip, take } = getPagination(query);
    const patientProfileId = await requireProfile("PATIENT", user.userId);

    const where = { patientId: patientProfileId };

    const [total, items] = await Promise.all([
        prisma.medicalRecord.count({ where }),
        prisma.medicalRecord.findMany({
            where,
            include: MEDICAL_RECORD_INCLUDE,
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    return { items, meta: buildMeta(total, page, limit) };
};

const getMedicalRecordById = async (id, user) => {
    const record = await prisma.medicalRecord.findUnique({
        where: { id },
        include: MEDICAL_RECORD_INCLUDE
    });

    if (!record) {
        throw new ApiError("Medical record not found", 404, "MEDICAL_RECORD_NOT_FOUND");
    }

    if (user.role === "ADMIN") {
        return record;
    }

    if (user.role === "PATIENT") {
        const patientProfileId = await requireProfile("PATIENT", user.userId);

        if (record.patientId !== patientProfileId) {
            throw new ApiError(
                "You do not have permission to access this medical record",
                403,
                "UNAUTHORIZED_ACCESS"
            );
        }

        return record;
    }

    if (user.role === "DOCTOR") {
        const doctorProfileId = await requireProfile("DOCTOR", user.userId);

        const canAccess = record.consultationId && record.consultation?.doctorId === doctorProfileId;

        if (!canAccess) {
            throw new ApiError(
                "You do not have permission to access this medical record",
                403,
                "UNAUTHORIZED_ACCESS"
            );
        }

        return record;
    }

    throw new ApiError(
        "You do not have permission to access this medical record",
        403,
        "UNAUTHORIZED_ACCESS"
    );
};

const listDoctorMedicalRecords = async (user, query = {}) => {
    const { page, limit, skip, take } = getPagination(query);
    const doctorProfileId = await requireProfile("DOCTOR", user.userId);

    const where = { consultation: { doctorId: doctorProfileId } };

    const [total, items] = await Promise.all([
        prisma.medicalRecord.count({ where }),
        prisma.medicalRecord.findMany({
            where,
            include: MEDICAL_RECORD_INCLUDE,
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    return { items, meta: buildMeta(total, page, limit) };
};

module.exports = {
    createMedicalRecord,
    listMyMedicalRecords,
    getMedicalRecordById,
    listDoctorMedicalRecords
};
