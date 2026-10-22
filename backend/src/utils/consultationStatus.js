const CONSULTATION_TRANSITIONS = {
    PENDING: ["RINGING", "CANCELLED"],
    RINGING: ["ACTIVE", "REJECTED", "MISSED"],
    ACTIVE: ["COMPLETED", "CANCELLED"],
    COMPLETED: [],
    CANCELLED: [],
    REJECTED: [],
    MISSED: []
};

const canTransitionConsultationStatus = (currentStatus, newStatus) => {
    const allowed = CONSULTATION_TRANSITIONS[currentStatus] || [];

    return allowed.includes(newStatus);
};

module.exports = {
    CONSULTATION_TRANSITIONS,
    canTransitionConsultationStatus
};
