const prisma = require("../config/prisma");

const listPharmaciesWithInventory = async () => {
    return await prisma.pharmacy.findMany({
        include: {
            inventories: true,
        },
    });
};

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
    updateInventoryItem,
};
