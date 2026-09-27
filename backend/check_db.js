const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function main() {
  const cons = await prisma.consultation.findMany({ select: { id: true, status: true, patientId: true }});
  const pres = await prisma.prescription.findMany({ select: { id: true, diagnosis: true, consultationId: true, patientId: true, doctorId: true }});
  console.log("Consultations:", cons.length, cons);
  console.log("Prescriptions:", pres.length, pres);
}
main().catch(console.error).finally(()=>prisma.$disconnect());
