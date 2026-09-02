const { matchedData } = require("../middleware/validate");
const asyncHandler = require("../utils/asyncHandler");
const ashaService = require("../services/asha.service");

const createAshaWorker = asyncHandler(async (req, res) => {
    const ashaWorker = await ashaService.createAshaWorker(
        req.user.userId,
        matchedData(req)
    );

    res.status(201).json({
        success: true,
        message: "ASHA worker profile created successfully",
        data: ashaWorker
    });
});

const getMyAshaWorker = asyncHandler(async (req, res) => {
    const ashaWorker = await ashaService.getAshaWorkerByUserId(req.user.userId);

    res.json({
        success: true,
        message: "ASHA worker profile retrieved successfully",
        data: ashaWorker
    });
});

const updateMyAshaWorker = asyncHandler(async (req, res) => {
    const ashaWorker = await ashaService.updateAshaWorker(
        req.user.userId,
        matchedData(req)
    );

    res.json({
        success: true,
        message: "ASHA worker profile updated successfully",
        data: ashaWorker
    });
});

const listAshaWorkers = asyncHandler(async (req, res) => {
    const { items, meta } = await ashaService.listAshaWorkers(req.query);

    res.json({
        success: true,
        message: "ASHA workers retrieved successfully",
        data: items,
        meta
    });
});

const getAshaWorkerById = asyncHandler(async (req, res) => {
    const ashaWorker = await ashaService.getAshaWorkerById(req.params.id);

    res.json({
        success: true,
        message: "ASHA worker retrieved successfully",
        data: ashaWorker
    });
});

module.exports = {
    createAshaWorker,
    getMyAshaWorker,
    updateMyAshaWorker,
    listAshaWorkers,
    getAshaWorkerById
};
