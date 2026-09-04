const prisma = require("../config/prisma");
const ApiError = require("../utils/ApiError");
const { getPagination, buildMeta } = require("../utils/pagination");
const { getProfileIdForRole, requireProfile } = require("../utils/profile");
const { v4: uuidv4 } = require('uuid');

const USER_SELECT = { id: true, name: true, phone: true, email: true };

const generateMockABHARecords = (patientProfileId) => {
  return [
    {
      id: uuidv4(),
      patientId: patientProfileId,
      title: "Apollo Hospital - Complete Blood Count (CBC)",
      documentType: "LAB_REPORT",
      fileUrl: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
      source: "ABHA",
      issuedDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
      createdAt: new Date(),
      updatedAt: new Date(),
      patient: { user: { name: "Mock ABHA User" } }
    },
    {
      id: uuidv4(),
      patientId: patientProfileId,
      title: "AIIMS - Chest X-Ray",
      documentType: "X_RAY",
      fileUrl: "https://upload.wikimedia.org/wikipedia/commons/4/4b/Chest_radiograph_of_a_normal_human_male.jpg",
      source: "ABHA",
      issuedDate: new Date(Date.now() - 120 * 24 * 60 * 60 * 1000),
      createdAt: new Date(),
      updatedAt: new Date(),
      patient: { user: { name: "Mock ABHA User" } }
    }
  ];
};

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

    let allItems = [...items];
    // For MVP Presentation: Automatically simulating a connection to the ABDM grid.
    const abhaRecords = generateMockABHARecords(patientProfileId);
    allItems = [...allItems, ...abhaRecords];
    allItems.sort((a, b) => new Date(b.issuedDate || b.createdAt) - new Date(a.issuedDate || a.createdAt));

    return { items: allItems, meta: buildMeta(total, page, limit) };
};

const listDoctorPatientRecords = async (patientProfileId, query = {}) => {
    const { page, limit, skip, take } = getPagination(query);

    const where = { patientId: patientProfileId };

    const [total, items] = await Promise.all([
        prisma.medicalRecord.count({ where }),
        prisma.medicalRecord.findMany({
            where,
            include: { patient: { include: { user: { select: USER_SELECT } } } },
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    let allItems = [...items];
    const abhaRecords = generateMockABHARecords(patientProfileId);
    allItems = [...allItems, ...abhaRecords];
    allItems.sort((a, b) => new Date(b.issuedDate || b.createdAt) - new Date(a.issuedDate || a.createdAt));

    return { items: allItems, meta: buildMeta(total, page, limit) };
};

const uploadPatientRecord = async (user, data) => {
    const patientProfileId = await requireProfile("PATIENT", user.userId);
    return prisma.medicalRecord.create({
        data: {
            patientId: patientProfileId,
            title: data.title,
            documentType: data.documentType,
            fileUrl: data.fileUrl,
            source: 'MANUAL',
            issuedDate: data.issuedDate ? new Date(data.issuedDate) : new Date(),
        },
        include: { patient: { include: { user: { select: USER_SELECT } } } }
    });
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
    listDoctorMedicalRecords,
    uploadPatientRecord,
    listDoctorPatientRecords
};
