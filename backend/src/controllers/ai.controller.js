const asyncHandler = require('../utils/asyncHandler');
const aiService = require('../services/ai.service');
const prisma = require('../config/prisma');
const ApiError = require('../utils/ApiError');
const { getProfileIdForRole } = require('../utils/profile');

const resolveTrustedPatientId = async (req) => {
    if (req.user && req.user.role === 'PATIENT') {
        return req.user.patient ? req.user.patient.id : null;
    }

    if (!req.user || !['DOCTOR', 'ASHA'].includes(req.user.role)) {
        return null;
    }

    const requestedPatientId = req.body.patientId;
    if (!requestedPatientId) {
        return null;
    }

    const profileId = await getProfileIdForRole(req.user.role, req.user.userId);
    if (!profileId) {
        throw new ApiError('Professional profile not found', 403, 'FORBIDDEN');
    }

    const relationFilter = req.user.role === 'DOCTOR'
        ? { doctorId: profileId }
        : { ashaWorkerId: profileId };

    const linkedConsultation = await prisma.consultation.findFirst({
        where: {
            patientId: requestedPatientId,
            ...relationFilter
        },
        select: { id: true }
    });

    if (!linkedConsultation) {
        throw new ApiError(
            'You do not have permission to query this patient record',
            403,
            'FORBIDDEN'
        );
    }

    return requestedPatientId;
};

const queryAi = asyncHandler(async (req, res) => {
    const { query } = req.body;
    const requestId = req.headers['x-request-id'] || `req-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`;

    console.log(`[AI Controller] Query exists: ${Boolean(query)}`);
    console.log(`[AI Controller] Query length: ${query ? query.length : 0}`);

    if (!query) {
        return res.status(400).json({
            success: false,
            message: 'Query is required'
        });
    }

    try {
        // Never pass an arbitrary frontend patientId to the AI service.
        const patientId = await resolveTrustedPatientId(req);
        const aiResponse = await aiService.queryAgent(query, patientId, requestId);

        res.status(200).json({
            success: true,
            data: aiResponse
        });
    } catch (error) {
        const statusCode = error.statusCode || 500;
        res.status(statusCode).json({
            success: false,
            message: error.message
        });
    }
});

module.exports = {
    queryAi
};
