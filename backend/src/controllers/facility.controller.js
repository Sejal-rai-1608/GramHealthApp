const asyncHandler = require("../utils/asyncHandler");
const facilityService = require("../services/facility.service");

const listFacilities = asyncHandler(async (req, res) => {
    const { items, meta } = await facilityService.listFacilities(req.query);

    res.json({
        success: true,
        data: items,
        meta
    });
});

const getFacilityById = asyncHandler(async (req, res) => {
    const facility = await facilityService.getFacilityById(req.params.id);

    res.json({
        success: true,
        data: facility
    });
});

const createFacility = asyncHandler(async (req, res) => {
    const facility = await facilityService.createFacility(req.body);

    res.status(201).json({
        success: true,
        message: "Facility created successfully",
        data: facility
    });
});

const updateFacility = asyncHandler(async (req, res) => {
    const facility = await facilityService.updateFacility(req.params.id, req.body);

    res.json({
        success: true,
        message: "Facility updated successfully",
        data: facility
    });
});

const deleteFacility = asyncHandler(async (req, res) => {
    await facilityService.deleteFacility(req.params.id);

    res.json({
        success: true,
        message: "Facility deleted successfully"
    });
});

module.exports = {
    listFacilities,
    getFacilityById,
    createFacility,
    updateFacility,
    deleteFacility
};