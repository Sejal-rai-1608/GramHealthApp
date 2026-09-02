const express = require("express");

const { authenticate, authorize } = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validate");
const { createAshaWorker, updateAshaWorker, listAshaWorkers } = require("../validators/asha.validator");
const {
    createAshaWorker: createAshaWorkerCtrl,
    getMyAshaWorker,
    updateMyAshaWorker,
    listAshaWorkers: listAshaWorkersCtrl,
    getAshaWorkerById
} = require("../controllers/asha.controller");

const router = express.Router();

router.post("/", authenticate, authorize("ASHA"), validate(createAshaWorker), createAshaWorkerCtrl);
router.get("/me", authenticate, authorize("ASHA"), getMyAshaWorker);
router.patch("/me", authenticate, authorize("ASHA"), validate(updateAshaWorker), updateMyAshaWorker);

router.get("/", authenticate, authorize("ADMIN"), validate(listAshaWorkers), listAshaWorkersCtrl);
router.get("/:id", authenticate, authorize("ADMIN"), getAshaWorkerById);

module.exports = router;
