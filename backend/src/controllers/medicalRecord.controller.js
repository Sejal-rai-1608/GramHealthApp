const { matchedData } = require("../middleware/validate");
const asyncHandler = require("../utils/asyncHandler");
const medicalRecordService = require("../services/medicalRecord.service");

const createMedicalRecord = asyncHandler(async (req, res) => {
    const record = await medicalRecordService.createMedicalRecord(
        req.user,
        matchedData(req)
    );

    res.status(201).json({
        success: true,
        message: "Medical record created successfully",
        data: record
    });
});

const listMyMedicalRecords = asyncHandler(async (req, res) => {
    const { items, meta } = await medicalRecordService.listMyMedicalRecords(
        req.user,
        req.query
    );

    res.json({
        success: true,
        message: "Medical records retrieved successfully",
        data: items,
        meta
    });
});

const getMedicalRecordById = asyncHandler(async (req, res) => {
    const record = await medicalRecordService.getMedicalRecordById(
        req.params.id,
        req.user
    );

    res.json({
        success: true,
        message: "Medical record retrieved successfully",
        data: record
    });
});

const listDoctorMedicalRecords = asyncHandler(async (req, res) => {
    const { items, meta } = await medicalRecordService.listDoctorMedicalRecords(
        req.user,
        req.query
    );

    res.json({
        success: true,
        message: "Medical records retrieved successfully",
        data: items,
        meta
    });
});

const uploadPatientRecord = asyncHandler(async (req, res) => {
    const { title, documentType, fileUrl, issuedDate } = req.body;
    
    if (!title || !fileUrl) {
        return res.status(400).json({
            success: false,
            message: 'title, documentType, and fileUrl are required',
        });
    }

    const record = await medicalRecordService.uploadPatientRecord(req.user, {
        title,
        documentType,
        fileUrl,
        issuedDate
    });

    res.status(201).json({
        success: true,
        message: "Medical document uploaded successfully",
        data: record
    });
});

module.exports = {
    createMedicalRecord,
    listMyMedicalRecords,
    getMedicalRecordById,
    listDoctorMedicalRecords,
    uploadPatientRecord
};
