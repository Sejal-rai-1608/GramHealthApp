const prisma = require("../config/prisma");
const ApiError = require("../utils/ApiError");
const { getPagination, buildMeta } = require("../utils/pagination");

const USER_SELECT = { id: true, name: true, phone: true, email: true };

const createDoctor = async (userId, data) => {
    const existing = await prisma.doctor.findUnique({ where: { userId } });

    if (existing) {
        throw new ApiError("Doctor profile already exists", 409, "PROFILE_EXISTS");
    }

    return prisma.doctor.create({
        data: { userId, ...data }
    });
};

const getDoctorByUserId = async (userId) => {
    const doctor = await prisma.doctor.findUnique({
        where: { userId },
        include: { user: { select: USER_SELECT } }
    });

    if (!doctor) {
        throw new ApiError(
            "Doctor profile not found. Please create your doctor profile first.",
            404,
            "PROFILE_NOT_FOUND"
        );
    }

    return doctor;
};

const updateDoctor = async (userId, data) => {
    const existing = await prisma.doctor.findUnique({ where: { userId } });

    if (!existing) {
        throw new ApiError(
            "Doctor profile not found. Please create your doctor profile first.",
            404,
            "PROFILE_NOT_FOUND"
        );
    }

    if (Object.keys(data).length === 0) {
        return existing;
    }

    return prisma.doctor.update({
        where: { userId },
        data
    });
};

const listDoctors = async (query = {}) => {
    const { page, limit, skip, take } = getPagination(query);
    const { search, specialization, hospitalName } = query;

    const where = {};

    if (search) {
        where.OR = [
            { specialization: { contains: search, mode: "insensitive" } },
            { hospitalName: { contains: search, mode: "insensitive" } },
            { user: { name: { contains: search, mode: "insensitive" } } }
        ];
    }

    if (specialization) {
        where.specialization = { contains: specialization, mode: "insensitive" };
    }

    if (hospitalName) {
        where.hospitalName = { contains: hospitalName, mode: "insensitive" };
    }

    const [total, items] = await Promise.all([
        prisma.doctor.count({ where }),
        prisma.doctor.findMany({
            where,
            include: { user: { select: USER_SELECT } },
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    return { items, meta: buildMeta(total, page, limit) };
};

const getDoctorById = async (id) => {
    const doctor = await prisma.doctor.findUnique({
        where: { id },
        include: { user: { select: USER_SELECT } }
    });

    if (!doctor) {
        throw new ApiError("Doctor not found", 404, "NOT_FOUND");
    }

    return doctor;
};

module.exports = {
    createDoctor,
    getDoctorByUserId,
    updateDoctor,
    listDoctors,
    getDoctorById
};
