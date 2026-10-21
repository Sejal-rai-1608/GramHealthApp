const express = require("express");

const { authenticate, authorize } = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validate");
const { listUsers } = require("../validators/user.validator");
const {
    listUsers: listUsersCtrl,
    getUserById
} = require("../controllers/user.controller");

const router = express.Router();

router.get("/", authenticate, authorize("ADMIN"), validate(listUsers), listUsersCtrl);
router.get("/:id", authenticate, authorize("ADMIN"), getUserById);

module.exports = router;
