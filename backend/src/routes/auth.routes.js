const express = require("express");

const {
    register,
    login,
    resetPassword,
    forgotPassword,
    resetPasswordWithToken
} = require("../controllers/auth.controller");

const { validate } = require("../middleware/validate");
const { register: registerValidator } = require("../validators/auth.validator");

const router = express.Router();

router.post("/register", validate(registerValidator), register);
router.post("/login", login);
router.post("/forgot-password", forgotPassword);
router.post("/reset-password", resetPassword);
router.post("/reset-password/token", resetPasswordWithToken);

module.exports = router;