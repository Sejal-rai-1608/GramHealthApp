const asyncHandler = require("../utils/asyncHandler");
const reportService = require("../services/report.service");

const getOverview = asyncHandler(async (req, res) => {
    const stats = await reportService.getOverviewStats();
    res.json({ success: true, data: stats });
});

const getConsultationTrends = asyncHandler(async (req, res) => {
    const days = parseInt(req.query.days) || 30;
    const data = await reportService.getConsultationTrends(days);
    res.json({ success: true, data });
});

const getDoctorWorkload = asyncHandler(async (req, res) => {
    const data = await reportService.getDoctorWorkload();
    res.json({ success: true, data });
});

const getPharmacyCoverage = asyncHandler(async (req, res) => {
    const data = await reportService.getPharmacyCoverage();
    res.json({ success: true, data });
});

const getUserGrowth = asyncHandler(async (req, res) => {
    const days = parseInt(req.query.days) || 30;
    const data = await reportService.getUserGrowth(days);
    res.json({ success: true, data });
});

module.exports = {
    getOverview,
    getConsultationTrends,
    getDoctorWorkload,
    getPharmacyCoverage,
    getUserGrowth
};