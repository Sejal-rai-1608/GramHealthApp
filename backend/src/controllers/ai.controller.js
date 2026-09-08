const asyncHandler = require('../utils/asyncHandler');
const aiService = require('../services/ai.service');

const queryAi = asyncHandler(async (req, res) => {
    const { query } = req.body;

    if (!query) {
        return res.status(400).json({
            success: false,
            message: 'Query is required'
        });
    }

    // Determine trusted patientId
    let patientId = null;
    if (req.user && req.user.role === 'PATIENT' && req.user.patient) {
        patientId = req.user.patient.id;
    } else if (req.user && (req.user.role === 'DOCTOR' || req.user.role === 'ASHA') && req.body.patientId) {
        // If doctor/asha, they might query on behalf of a patient, but we should validate access if possible
        patientId = req.body.patientId;
    }

    try {
        const aiResponse = await aiService.queryAgent(query, patientId);

        res.status(200).json({
            success: true,
            data: aiResponse
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

module.exports = {
    queryAi
};
