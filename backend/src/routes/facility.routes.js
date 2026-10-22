const express = require("express");
const { authenticate, authorize } = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validate");
const { uuidParam } = require("../validators/common.validator");
const {
    listFacilities,
    getFacilityById,
    createFacility,
    updateFacility,
    deleteFacility
} = require("../controllers/facility.controller");

const router = express.Router();

router.get("/", authenticate, authorize("ADMIN"), listFacilities);
router.get("/:id", authenticate, authorize("ADMIN"), validate(uuidParam()), getFacilityById);
router.post("/", authenticate, authorize("ADMIN"), createFacility);
router.patch("/:id", authenticate, authorize("ADMIN"), validate(uuidParam()), updateFacility);
router.delete("/:id", authenticate, authorize("ADMIN"), validate(uuidParam()), deleteFacility);

module.exports = router;