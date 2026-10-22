const prisma = require("../config/prisma");
const { getPagination, buildMeta } = require("../utils/pagination");

const listFacilities = async (query = {}) => {
    const { page, limit, skip, take } = getPagination(query);
    const { search, type, isActive } = query;

    const where = {};

    if (search) {
        where.OR = [
            { name: { contains: search, mode: "insensitive" } },
            { address: { contains: search, mode: "insensitive" } }
        ];
    }

    if (type) {
        where.type = type;
    }

    if (isActive !== undefined) {
        where.isActive = isActive === "true";
    }

    const [total, items] = await Promise.all([
        prisma.facility.count({ where }),
        prisma.facility.findMany({
            where,
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    return { items, meta: buildMeta(total, page, limit) };
};

const getFacilityById = async (id) => {
    const facility = await prisma.facility.findUnique({ where: { id } });

    if (!facility) {
        throw new Error("Facility not found");
    }

    return facility;
};

const createFacility = async (data) => {
    return prisma.facility.create({ data });
};

const updateFacility = async (id, data) => {
    const existing = await prisma.facility.findUnique({ where: { id } });

    if (!existing) {
        throw new Error("Facility not found");
    }

    return prisma.facility.update({
        where: { id },
        data
    });
};

const deleteFacility = async (id) => {
    const existing = await prisma.facility.findUnique({ where: { id } });

    if (!existing) {
        throw new Error("Facility not found");
    }

    return prisma.facility.delete({ where: { id } });
};

module.exports = {
    listFacilities,
    getFacilityById,
    createFacility,
    updateFacility,
    deleteFacility
};