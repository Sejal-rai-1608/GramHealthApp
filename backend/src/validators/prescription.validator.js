const { body, query } = require("express-validator");
const { paginationQuery, uuidParam } = require("./common.validator");

const REQUIRED_MEDICINE_FIELDS = ["name", "dosage", "frequency", "duration"];
const MAX_FIELD_LENGTH = {
    name: 200,
    dosage: 200,
    frequency: 200,
    duration: 100,
    instructions: 2000
};

const validateMedicines = (value) => {
    if (!Array.isArray(value)) {
        throw new Error("medicines must be an array");
    }

    if (value.length === 0) {
        throw new Error("medicines must not be empty");
    }

    value.forEach((item, index) => {
        if (item === null || typeof item !== "object" || Array.isArray(item)) {
            throw new Error(`medicines[${index}] must be an object`);
        }

        for (const field of REQUIRED_MEDICINE_FIELDS) {
            const fieldValue = item[field];

            if (typeof fieldValue !== "string" || fieldValue.trim() === "") {
                throw new Error(`medicines[${index}].${field} is required and must be a non-empty string`);
            }

            if (fieldValue.trim().length > MAX_FIELD_LENGTH[field]) {
                throw new Error(`medicines[${index}].${field} must be at most ${MAX_FIELD_LENGTH[field]} characters`);
            }
        }

        if (item.instructions !== undefined) {
            if (typeof item.instructions !== "string") {
                throw new Error(`medicines[${index}].instructions must be a string`);
            }

            if (item.instructions.trim().length > MAX_FIELD_LENGTH.instructions) {
                throw new Error(`medicines[${index}].instructions must be at most ${MAX_FIELD_LENGTH.instructions} characters`);
            }
        }
    });

    return true;
};

const createPrescription = [
    body("consultationId")
        .isUUID().withMessage("consultationId must be a valid UUID"),
    body("medicines")
        .custom(validateMedicines),
    body("instructions")
        .optional({ values: "falsy" })
        .trim()
        .isLength({ max: 5000 }).withMessage("instructions must be at most 5000 characters")
];

const prescriptionParam = uuidParam("id");

const listMyPrescriptions = paginationQuery;

const listDoctorPrescriptions = [
    ...paginationQuery,
    query("patientId")
        .optional()
        .isUUID().withMessage("patientId must be a valid UUID")
];

module.exports = {
    createPrescription,
    prescriptionParam,
    listMyPrescriptions,
    listDoctorPrescriptions
};
