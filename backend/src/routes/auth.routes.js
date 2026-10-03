const express = require("express");

const {
    register,
    login,
    resetPassword
} = require("../controllers/auth.controller");

const { validate } = require("../middleware/validate");
const { register: registerValidator } = require("../validators/auth.validator");

const router = express.Router();

router.post("/register", validate(registerValidator), register);
router.post("/login", login);
router.post("/reset-password", resetPassword);

module.exports = router;