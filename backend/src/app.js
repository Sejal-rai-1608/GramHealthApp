const express = require("express");
const cors = require("cors");

const app = express();

const authRoutes = require("./routes/auth.routes");
const testRoutes = require("./routes/test.routes");
const userRoutes = require("./routes/user.routes");
const patientRoutes = require("./routes/patient.routes");
const doctorRoutes = require("./routes/doctor.routes");
const ashaRoutes = require("./routes/asha.routes");
const consultationRoutes = require("./routes/consultation.routes");
const medicalRecordRoutes = require("./routes/medicalRecord.routes");
const prescriptionRoutes = require("./routes/prescription.routes");

const { notFound } = require("./middleware/notFound");
const { errorHandler } = require("./middleware/errorHandler");

app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    // Allow all during development — restrict to specific domains in production
    return callback(null, true);
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());

app.get("/", (req, res) => {
  res.json({ 
        message: "Welcome to the GramHealth API!",
        status: "success",
        version: "1.0.0"
    });
});

app.get("/api/health", (req, res) => {
  res.json({ 
        message: "API is healthy!",
        status: "healthy",
        version: "1.0.0"
    });
});


app.use("/api/auth", authRoutes);
app.use("/api/test", testRoutes);
app.use("/api/users", userRoutes);
app.use("/api/patients", patientRoutes);
app.use("/api/doctors", doctorRoutes);
app.use("/api/asha-workers", ashaRoutes);
app.use("/api/consultations", consultationRoutes);
app.use("/api/medical-records", medicalRecordRoutes);
app.use("/api/prescriptions", prescriptionRoutes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;