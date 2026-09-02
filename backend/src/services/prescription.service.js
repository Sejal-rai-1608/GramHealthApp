const prisma = require("../config/prisma");
const ApiError = require("../utils/ApiError");
const { getPagination, buildMeta } = require("../utils/pagination");
const { requireProfile } = require("../utils/profile");

const USER_SELECT = { id: true, name: true, phone: true, email: true };

const PRESCRIPTION_INCLUDE = {
    patient: { include: { user: { select: USER_SELECT } } },
    doctor: { include: { user: { select: USER_SELECT } } },
    consultation: true
};

const sanitizeMedicines = (medicines) => {
    return medicines.map((medicine) => {
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
};

const createPrescription = async (user, { consultationId, medicines, instructions }) => {
    const doctorProfileId = await requireProfile("DOCTOR", user.userId);

    const consultation = await prisma.consultation.findUnique({
        where: { id: consultationId }
    });

    if (!consultation) {
        throw new ApiError("Consultation not found", 404, "CONSULTATION_NOT_FOUND");
    }

    if (consultation.doctorId !== doctorProfileId) {
        throw new ApiError(
            "Only the assigned doctor can write a prescription for this consultation",
            403,
            "UNAUTHORIZED_ACCESS"
        );
    }

    if (consultation.status !== "ACTIVE") {
        throw new ApiError(
            `Prescriptions can only be created for active consultations (current status: ${consultation.status})`,
            400,
            "INVALID_CONSULTATION_STATE"
        );
    }

    return prisma.prescription.create({
        data: {
            patientId: consultation.patientId,
            consultationId,
            doctorId: doctorProfileId,
            medicines: sanitizeMedicines(medicines),
            instructions
        },
        include: PRESCRIPTION_INCLUDE
    });
};

const listMyPrescriptions = async (user, query = {}) => {
    const { page, limit, skip, take } = getPagination(query);
    const patientProfileId = await requireProfile("PATIENT", user.userId);

    const where = { patientId: patientProfileId };

    const [total, items] = await Promise.all([
        prisma.prescription.count({ where }),
        prisma.prescription.findMany({
            where,
            include: PRESCRIPTION_INCLUDE,
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    return { items, meta: buildMeta(total, page, limit) };
};

const getPrescriptionById = async (id, user) => {
    const prescription = await prisma.prescription.findUnique({
        where: { id },
        include: PRESCRIPTION_INCLUDE
    });

    if (!prescription) {
        throw new ApiError("Prescription not found", 404, "PRESCRIPTION_NOT_FOUND");
    }

    if (user.role === "ADMIN") {
        return prescription;
    }

    if (user.role === "PATIENT") {
        const patientProfileId = await requireProfile("PATIENT", user.userId);

        if (prescription.patientId !== patientProfileId) {
            throw new ApiError(
                "You do not have permission to access this prescription",
                403,
                "UNAUTHORIZED_ACCESS"
            );
        }

        return prescription;
    }

    if (user.role === "DOCTOR") {
        const doctorProfileId = await requireProfile("DOCTOR", user.userId);

        if (prescription.doctorId !== doctorProfileId) {
            throw new ApiError(
                "You do not have permission to access this prescription",
                403,
                "UNAUTHORIZED_ACCESS"
            );
        }

        return prescription;
    }

    throw new ApiError(
        "You do not have permission to access this prescription",
        403,
        "UNAUTHORIZED_ACCESS"
    );
};

const listDoctorPrescriptions = async (user, query = {}) => {
    const { page, limit, skip, take } = getPagination(query);
    const doctorProfileId = await requireProfile("DOCTOR", user.userId);

    const where = { doctorId: doctorProfileId };

    if (query.patientId) {
        where.patientId = query.patientId;
    }

    const [total, items] = await Promise.all([
        prisma.prescription.count({ where }),
        prisma.prescription.findMany({
            where,
            include: PRESCRIPTION_INCLUDE,
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    return { items, meta: buildMeta(total, page, limit) };
};

module.exports = {
    createPrescription,
    listMyPrescriptions,
    getPrescriptionById,
    listDoctorPrescriptions
};
