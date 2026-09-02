const express = require("express");

const {
    authenticate,
    authorize
} = require("../middleware/auth.middleware");

const router = express.Router();


router.get("/protected", authenticate, (req, res) => {

    res.json({
        success: true,
        message: "You are authenticated",
        user: req.user
    });

});


router.get(
    "/patient-only",
    authenticate,
    authorize("PATIENT"),
    (req, res) => {

        res.json({
            success: true,
            message: "Patient-only route accessed",
            user: req.user
        });

    }
);


router.get(
    "/doctor-only",
    authenticate,
    authorize("DOCTOR"),
    (req, res) => {

        res.json({
            success: true,
            message: "Doctor-only route accessed",
            user: req.user
        });

    }
);


module.exports = router;