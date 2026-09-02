const prisma = require("../config/prisma");
const ApiError = require("../utils/ApiError");
const { getPagination, buildMeta } = require("../utils/pagination");

const USER_SELECT = { id: true, name: true, phone: true, email: true };

const createPatient = async (userId, data) => {
    const existing = await prisma.patient.findUnique({ where: { userId } });

    if (existing) {
        throw new ApiError("Patient profile already exists", 409, "PROFILE_EXISTS");
    }

    return prisma.patient.create({
        data: { userId, ...data }
    });
};

const getPatientByUserId = async (userId) => {
    const patient = await prisma.patient.findUnique({
        where: { userId },
        include: { user: { select: USER_SELECT } }
    });

    if (!patient) {
        throw new ApiError(
            "Patient profile not found. Please create your patient profile first.",
            404,
            "PROFILE_NOT_FOUND"
        );
    }

    return patient;
};

const updatePatient = async (userId, data) => {
    const existing = await prisma.patient.findUnique({ where: { userId } });

    if (!existing) {
        throw new ApiError(
            "Patient profile not found. Please create your patient profile first.",
            404,
            "PROFILE_NOT_FOUND"
        );
    }

    if (Object.keys(data).length === 0) {
        return existing;
    }

    return prisma.patient.update({
        where: { userId },
        data
    });
};

const listPatients = async (query = {}) => {
    const { page, limit, skip, take } = getPagination(query);
    const { search } = query;

    const where = search
        ? {
            OR: [
                { village: { contains: search, mode: "insensitive" } },
                { district: { contains: search, mode: "insensitive" } },
                { state: { contains: search, mode: "insensitive" } },
                { user: { name: { contains: search, mode: "insensitive" } } }
            ]
        }
        : {};

    const [total, items] = await Promise.all([
        prisma.patient.count({ where }),
        prisma.patient.findMany({
            where,
            include: { user: { select: USER_SELECT } },
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    return { items, meta: buildMeta(total, page, limit) };
};

const getPatientById = async (id) => {
    const patient = await prisma.patient.findUnique({
        where: { id },
        include: { user: { select: USER_SELECT } }
    });

    if (!patient) {
        throw new ApiError("Patient not found", 404, "NOT_FOUND");
    }

    return patient;
};

module.exports = {
    createPatient,
    getPatientByUserId,
    updatePatient,
    listPatients,
    getPatientById
};
