const express = require("express");

const {
    register,
    login
} = require("../controllers/auth.controller");

const { validate } = require("../middleware/validate");
const { register: registerValidator } = require("../validators/auth.validator");

const router = express.Router();

router.post("/register", validate(registerValidator), register);
router.post("/login", login);

module.exports = router;