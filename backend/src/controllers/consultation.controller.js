const { matchedData } = require("../middleware/validate");
const asyncHandler = require("../utils/asyncHandler");
const consultationService = require("../services/consultation.service");

const createConsultation = asyncHandler(async (req, res) => {
    const consultation = await consultationService.createConsultation(
        req.user,
        matchedData(req)
    );

    res.status(201).json({
        success: true,
        message: "Consultation created successfully",
        data: consultation
    });
});

const getConsultationById = asyncHandler(async (req, res) => {
    const consultation = await consultationService.getConsultationById(
        req.params.id,
        req.user
    );

    res.json({
        success: true,
        message: "Consultation retrieved successfully",
        data: consultation
    });
});

const listConsultations = asyncHandler(async (req, res) => {
    const { items, meta } = await consultationService.listConsultations(
        req.user,
        req.query
    );

    res.json({
        success: true,
        message: "Consultations retrieved successfully",
        data: items,
        meta
    });
});

const updateStatus = asyncHandler(async (req, res) => {
    const consultation = await consultationService.updateStatus(
        req.params.id,
        req.user,
        matchedData(req)
    );

    res.json({
        success: true,
        message: "Consultation status updated successfully",
        data: consultation
    });
});

const acceptConsultation = asyncHandler(async (req, res) => {
    const consultation = await consultationService.acceptConsultation(
        req.params.id,
        req.user,
        matchedData(req)
    );

    res.json({
        success: true,
        message: "Consultation accepted successfully",
        data: consultation
    });
});

const completeConsultation = asyncHandler(async (req, res) => {
    const consultation = await consultationService.completeConsultation(
        req.params.id,
        req.user,
        matchedData(req)
    );

    res.json({
        success: true,
        message: "Consultation completed successfully",
        data: consultation
    });
});

const assignDoctor = asyncHandler(async (req, res) => {
    const consultation = await consultationService.assignDoctor(
        req.params.id,
        req.user,
        matchedData(req)
    );

    res.json({
        success: true,
        message: "Doctor assigned to consultation successfully",
        data: consultation
    });
});

module.exports = {
    createConsultation,
    getConsultationById,
    listConsultations,
    updateStatus,
    acceptConsultation,
    completeConsultation,
    assignDoctor
};
