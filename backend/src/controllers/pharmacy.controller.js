const pharmacyService = require("../services/pharmacy.service");

const list = async (req, res) => {
    try {
        const { items, meta } = await pharmacyService.listPharmaciesWithInventory(req.query);
        res.status(200).json({
            success: true,
            data: items,
            meta
        });
    } catch (error) {
        console.error("List pharmacies error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to list pharmacies",
        });
    }
};

const search = async (req, res) => {
    try {
        const { medicineName, lat, lon, radiusKm = 50 } = req.query;

        if (!medicineName || !lat || !lon) {
            return res.status(400).json({
                success: false,
                message: "medicineName, lat, and lon are required",
            });
        }

        const results = await pharmacyService.searchPharmaciesByMedicine(
            medicineName,
            parseFloat(lat),
            parseFloat(lon),
            parseFloat(radiusKm)
        );

        res.status(200).json({
            success: true,
            data: results,
        });
    } catch (error) {
        console.error("Search pharmacies error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to search pharmacies",
        });
    }
};

const updateInventory = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { medicineName, inStock } = req.body;

        if (!medicineName || inStock === undefined) {
            return res.status(400).json({
                success: false,
                message: "medicineName and inStock are required",
            });
        }

        const inventory = await pharmacyService.updateInventoryItem(userId, medicineName, inStock);
        
        res.status(200).json({
            success: true,
            message: "Inventory updated successfully",
            data: inventory,
        });
    } catch (error) {
        console.error("Update inventory error:", error);
        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
};

module.exports = {
    list,
    search,
    updateInventory,
};