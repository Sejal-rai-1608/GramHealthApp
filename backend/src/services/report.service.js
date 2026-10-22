const prisma = require("../config/prisma");

const getOverviewStats = async () => {
    const [
        totalUsers,
        totalDoctors,
        totalPatients,
        totalPharmacies,
        totalFacilities,
        totalConsultations,
        pendingConsultations,
        completedConsultations,
        totalPrescriptions
    ] = await Promise.all([
        prisma.user.count(),
        prisma.doctor.count(),
        prisma.patient.count(),
        prisma.pharmacy.count(),
        prisma.facility.count(),
        prisma.consultation.count(),
        prisma.consultation.count({ where: { status: "PENDING" } }),
        prisma.consultation.count({ where: { status: "COMPLETED" } }),
        prisma.prescription.count()
    ]);

    return {
        totalUsers,
        totalDoctors,
        totalPatients,
        totalPharmacies,
        totalFacilities,
        totalConsultations,
        pendingConsultations,
        completedConsultations,
        totalPrescriptions
    };
};

const getConsultationTrends = async (days = 30) => {
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    const consultations = await prisma.consultation.findMany({
        where: { createdAt: { gte: since } },
        select: { createdAt: true, status: true, type: true }
    });

    // Aggregate by day
    const dailyStats = {};
    consultations.forEach(c => {
        const date = c.createdAt.toISOString().split("T")[0];
        if (!dailyStats[date]) {
            dailyStats[date] = { date, total: 0, byStatus: {}, byType: {} };
        }
        dailyStats[date].total++;
        dailyStats[date].byStatus[c.status] = (dailyStats[date].byStatus[c.status] || 0) + 1;
        dailyStats[date].byType[c.type] = (dailyStats[date].byType[c.type] || 0) + 1;
    });

    return Object.values(dailyStats).sort((a, b) => a.date.localeCompare(b.date));
};

const getDoctorWorkload = async () => {
    const doctors = await prisma.doctor.findMany({
        include: {
            user: { select: { id: true, name: true, email: true } },
            _count: { select: { consultations: true, prescriptions: true } },
            consultations: {
                where: { status: "COMPLETED" },
                select: { riskLevel: true }
            }
        }
    });

    return doctors.map(d => ({
        id: d.id,
        name: d.user.name,
        email: d.user.email,
        specialization: d.specialization,
        hospitalName: d.hospitalName,
        totalConsultations: d._count.consultations,
        totalPrescriptions: d._count.prescriptions,
        completedConsultations: d.consultations.length
    }));
};

const getPharmacyCoverage = async () => {
    const pharmacies = await prisma.pharmacy.findMany({
        include: {
            _count: { select: { inventories: true } },
            inventories: { where: { inStock: true }, select: { medicineName: true } }
        }
    });

    return pharmacies.map(p => ({
        id: p.id,
        name: p.name,
        address: p.address,
        latitude: p.latitude,
        longitude: p.longitude,
        totalMedicines: p._count.inventories,
        inStockCount: p.inventories.length,
        stockPercentage: p._count.inventories > 0 
            ? Math.round((p.inventories.length / p._count.inventories) * 100) 
            : 0
    }));
};

const getUserGrowth = async (days = 30) => {
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    const users = await prisma.user.findMany({
        where: { createdAt: { gte: since } },
        select: { createdAt: true, role: true }
    });

    const dailyStats = {};
    users.forEach(u => {
        const date = u.createdAt.toISOString().split("T")[0];
        if (!dailyStats[date]) {
            dailyStats[date] = { date, total: 0, byRole: {} };
        }
        dailyStats[date].total++;
        dailyStats[date].byRole[u.role] = (dailyStats[date].byRole[u.role] || 0) + 1;
    });

    return Object.values(dailyStats).sort((a, b) => a.date.localeCompare(b.date));
};

module.exports = {
    getOverviewStats,
    getConsultationTrends,
    getDoctorWorkload,
    getPharmacyCoverage,
    getUserGrowth
};