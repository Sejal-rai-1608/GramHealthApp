const { matchedData } = require("../middleware/validate");
const asyncHandler = require("../utils/asyncHandler");
const prescriptionService = require("../services/prescription.service");

const createPrescription = asyncHandler(async (req, res) => {
    const prescription = await prescriptionService.createPrescription(
        req.user,
        matchedData(req)
    );

    res.status(201).json({
        success: true,
        message: "Prescription created successfully",
        data: prescription
    });
});

const listMyPrescriptions = asyncHandler(async (req, res) => {
    const { items, meta } = await prescriptionService.listMyPrescriptions(
        req.user,
        req.query
    );

    res.json({
        success: true,
        message: "Prescriptions retrieved successfully",
        data: items,
        meta
    });
});

const getPrescriptionById = asyncHandler(async (req, res) => {
    const prescription = await prescriptionService.getPrescriptionById(
        req.params.id,
        req.user
    );

    res.json({
        success: true,
        message: "Prescription retrieved successfully",
        data: prescription
    });
});

const listDoctorPrescriptions = asyncHandler(async (req, res) => {
    const { items, meta } = await prescriptionService.listDoctorPrescriptions(
        req.user,
        req.query
    );

    res.json({
        success: true,
        message: "Prescriptions retrieved successfully",
        data: items,
        meta
    });
});

module.exports = {
    createPrescription,
    listMyPrescriptions,
    getPrescriptionById,
    listDoctorPrescriptions
};
