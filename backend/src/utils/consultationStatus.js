const CONSULTATION_TRANSITIONS = {
    PENDING: ["ACTIVE", "CANCELLED"],
    ACTIVE: ["COMPLETED", "CANCELLED"],
    COMPLETED: [],
    CANCELLED: []
};

const canTransitionConsultationStatus = (currentStatus, newStatus) => {
    const allowed = CONSULTATION_TRANSITIONS[currentStatus] || [];

    return allowed.includes(newStatus);
};

module.exports = {
    CONSULTATION_TRANSITIONS,
    canTransitionConsultationStatus
};
