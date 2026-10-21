const { matchedData } = require("../middleware/validate");
const asyncHandler = require("../utils/asyncHandler");
const patientService = require("../services/patient.service");

const createPatient = asyncHandler(async (req, res) => {
    const patient = await patientService.createPatient(
        req.user.userId,
        matchedData(req)
    );

    res.status(201).json({
        success: true,
        message: "Patient profile created successfully",
        data: patient
    });
});

const getMyPatient = asyncHandler(async (req, res) => {
    const patient = await patientService.getPatientByUserId(req.user.userId);

    res.json({
        success: true,
        message: "Patient profile retrieved successfully",
        data: patient
    });
});

const updateMyPatient = asyncHandler(async (req, res) => {
    const patient = await patientService.updatePatient(
        req.user.userId,
        matchedData(req)
    );

    res.json({
        success: true,
        message: "Patient profile updated successfully",
        data: patient
    });
});

const listPatients = asyncHandler(async (req, res) => {
    const { items, meta } = await patientService.listPatients(req.query);

    res.json({
        success: true,
        message: "Patients retrieved successfully",
        data: items,
        meta
    });
});

const getPatientById = asyncHandler(async (req, res) => {
    const patient = await patientService.getPatientById(req.params.id);

    res.json({
        success: true,
        message: "Patient retrieved successfully",
        data: patient
    });
});

module.exports = {
    createPatient,
    getMyPatient,
    updateMyPatient,
    listPatients,
    getPatientById
};
