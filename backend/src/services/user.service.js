const prisma = require("../config/prisma");
const ApiError = require("../utils/ApiError");
const { getPagination, buildMeta } = require("../utils/pagination");

const listUsers = async (query = {}) => {
    const { page, limit, skip, take } = getPagination(query);
    const { search, role } = query;

    const where = {};

    if (role) {
        where.role = role;
    }

    if (search) {
        where.OR = [
            { name: { contains: search, mode: "insensitive" } },
            { phone: { contains: search, mode: "insensitive" } },
            { email: { contains: search, mode: "insensitive" } }
        ];
    }

    const [total, items] = await Promise.all([
        prisma.user.count({ where }),
        prisma.user.findMany({
            where,
            select: {
                id: true,
                name: true,
                phone: true,
                email: true,
                role: true,
                createdAt: true,
                updatedAt: true
            },
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    return { items, meta: buildMeta(total, page, limit) };
};

const getUserById = async (id) => {
    const user = await prisma.user.findUnique({
        where: { id },
        select: {
            id: true,
            name: true,
            phone: true,
            email: true,
            role: true,
            createdAt: true,
            updatedAt: true,
            patient: {
                select: {
                    id: true,
                    dateOfBirth: true,
                    gender: true,
                    village: true,
                    district: true,
                    state: true
                }
            },
            doctor: {
                select: {
                    id: true,
                    specialization: true,
                    registrationNumber: true,
                    hospitalName: true
                }
            },
            ashaWorker: {
                select: {
                    id: true,
                    village: true,
                    district: true,
                    state: true
                }
            }
        }
    });

    if (!user) {
        throw new ApiError("User not found", 404, "USER_NOT_FOUND");
    }

    return user;
};

module.exports = {
    listUsers,
    getUserById
};
