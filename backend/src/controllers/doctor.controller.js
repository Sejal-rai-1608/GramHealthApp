const { matchedData } = require("../middleware/validate");
const asyncHandler = require("../utils/asyncHandler");
const doctorService = require("../services/doctor.service");
const consultationService = require("../services/consultation.service");

const createDoctor = asyncHandler(async (req, res) => {
    const doctor = await doctorService.createDoctor(
        req.user.userId,
        matchedData(req)
    );

    res.status(201).json({
        success: true,
        message: "Doctor profile created successfully",
        data: doctor
    });
});

const getMyDoctor = asyncHandler(async (req, res) => {
    const doctor = await doctorService.getDoctorByUserId(req.user.userId);

    res.json({
        success: true,
        message: "Doctor profile retrieved successfully",
        data: doctor
    });
});

const updateMyDoctor = asyncHandler(async (req, res) => {
    const doctor = await doctorService.updateDoctor(
        req.user.userId,
        matchedData(req)
    );

    res.json({
        success: true,
        message: "Doctor profile updated successfully",
        data: doctor
    });
});

const listDoctors = asyncHandler(async (req, res) => {
    const { items, meta } = await doctorService.listDoctors(req.query);

    res.json({
        success: true,
        message: "Doctors retrieved successfully",
        data: items,
        meta
    });
});

const getDoctorById = asyncHandler(async (req, res) => {
    const doctor = await doctorService.getDoctorById(req.params.id);

    res.json({
        success: true,
        message: "Doctor retrieved successfully",
        data: doctor
    });
});

const listDoctorConsultations = asyncHandler(async (req, res) => {
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

module.exports = {
    createDoctor,
    getMyDoctor,
    updateMyDoctor,
    listDoctors,
    getDoctorById,
    listDoctorConsultations
};
