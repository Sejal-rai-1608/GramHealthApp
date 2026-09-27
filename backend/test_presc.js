require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const prescriptionService = require('./src/services/prescription.service');
const { getProfileIdForRole } = require("./src/utils/profile");

async function main() {
  try {
    const consultation = await prisma.consultation.findFirst({ select: { id: true, doctorId: true, status: true, patientId: true }});
    if (!consultation || !consultation.doctorId) return console.log('no consultation');
    console.log("Found:", consultation);
    
    // find doctor user
    const doc = await prisma.doctor.findUnique({ where: { id: consultation.doctorId }});
    // mock user
    const user = { userId: doc.userId, role: 'DOCTOR' };
    
    const payload = {
       consultationId: consultation.id,
       medicines: [{name: 'Paracetamol', dosage: '500mg', frequency: 'twice', duration: '3 days'}],
       instructions: "Test notes"
    };
    console.log("Submitting...");
    const res = await prescriptionService.createPrescription(user, payload);
    console.log("Success:", JSON.stringify(res, null, 2));
  } catch (err) {
    console.error("FAIL:", err);
  }
}
main().finally(()=>prisma.$disconnect());
