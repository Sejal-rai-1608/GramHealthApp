const prisma = require("../config/prisma");
const { getPagination, buildMeta } = require("../utils/pagination");

const listPharmaciesWithInventory = async (query = {}) => {
    const { page, limit, skip, take } = getPagination(query);
    const { search } = query;

    const where = search
        ? {
            OR: [
                { name: { contains: search, mode: "insensitive" } },
                { address: { contains: search, mode: "insensitive" } }
            ]
        }
        : {};

    const [total, items] = await Promise.all([
        prisma.pharmacy.count({ where }),
        prisma.pharmacy.findMany({
            where,
            include: { inventories: true },
            orderBy: { createdAt: "desc" },
            skip,
            take
        })
    ]);

    return { items, meta: buildMeta(total, page, limit) };
};

const searchPharmaciesByMedicine = async (medicineName, lat, lon, radiusKm = 50) => {
    const pharmacies = await prisma.pharmacy.findMany({
        include: {
            inventories: {
                where: {
                    medicineName: {
                        contains: medicineName,
                        mode: "insensitive",
                    },
                    inStock: true,
                },
            },
        },
    });

    const results = [];
    for (const pharmacy of pharmacies) {
        if (pharmacy.inventories.length === 0) continue;

        const distance = calculateDistance(
            lat,
            lon,
            pharmacy.latitude,
            pharmacy.longitude
        );

        if (distance <= radiusKm) {
            results.push({
                pharmacy,
                distanceKm: Math.round(distance * 10) / 10,
                isAvailable: true,
            });
        }
    }

    results.sort((a, b) => a.distanceKm - b.distanceKm);
    return results;
};

function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos((lat1 * Math.PI) / 180) *
            Math.cos((lat2 * Math.PI) / 180) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

const updateInventoryItem = async (userId, medicineName, inStock) => {
    const pharmacy = await prisma.pharmacy.findUnique({
        where: { userId },
    });

    if (!pharmacy) {
        throw new Error("Pharmacy profile not found for this user");
    }

    // Find existing inventory item or create it
    let inventory = await prisma.pharmacyInventory.findFirst({
        where: {
            pharmacyId: pharmacy.id,
            medicineName: medicineName,
        }
    });

    if (inventory) {
        inventory = await prisma.pharmacyInventory.update({
            where: { id: inventory.id },
            data: { inStock },
        });
    } else {
        inventory = await prisma.pharmacyInventory.create({
            data: {
                pharmacyId: pharmacy.id,
                medicineName,
                inStock,
            },
        });
    }

    return inventory;
};

module.exports = {
    listPharmaciesWithInventory,
    searchPharmaciesByMedicine,
    updateInventoryItem,
};