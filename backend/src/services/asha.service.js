const prisma = require("../config/prisma");
const ApiError = require("../utils/ApiError");
const { getPagination, buildMeta } = require("../utils/pagination");

const USER_SELECT = { id: true, name: true, phone: true, email: true };

const createAshaWorker = async (userId, data) => {
    const existing = await prisma.ashaWorker.findUnique({ where: { userId } });

    if (existing) {
        throw new ApiError("ASHA worker profile already exists", 409, "PROFILE_EXISTS");
    }

    return prisma.ashaWorker.create({
        data: { userId, ...data }
    });
};

const getAshaWorkerByUserId = async (userId) => {
    const ashaWorker = await prisma.ashaWorker.findUnique({
        where: { userId },
        include: { user: { select: USER_SELECT } }
    });

    if (!ashaWorker) {
        throw new ApiError(
            "ASHA worker profile not found. Please create your ASHA worker profile first.",
            404,
            "PROFILE_NOT_FOUND"
        );
    }

    return ashaWorker;
};

const updateAshaWorker = async (userId, data) => {
    const existing = await prisma.ashaWorker.findUnique({ where: { userId } });

    if (!existing) {
        throw new ApiError(
            "ASHA worker profile not found. Please create your ASHA worker profile first.",
            404,
            "PROFILE_NOT_FOUND"
        );
    }

    if (Object.keys(data).length === 0) {
        return existing;
    }

    return prisma.ashaWorker.update({
        where: { userId },
        data
    });
};

const listAshaWorkers = async (query = {}) => {
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
        prisma.ashaWorker.count({ where }),
        prisma.ashaWorker.findMany({
            where,
            include: { user: { select: USER_SELECT } },
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    return { items, meta: buildMeta(total, page, limit) };
};

const getAshaWorkerById = async (id) => {
    const ashaWorker = await prisma.ashaWorker.findUnique({
        where: { id },
        include: { user: { select: USER_SELECT } }
    });

    if (!ashaWorker) {
        throw new ApiError("ASHA worker not found", 404, "NOT_FOUND");
    }

    return ashaWorker;
};

module.exports = {
    createAshaWorker,
    getAshaWorkerByUserId,
    updateAshaWorker,
    listAshaWorkers,
    getAshaWorkerById
};
