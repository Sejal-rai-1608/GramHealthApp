const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
(async () => {
  try {
    const duplicates = await prisma.$queryRaw`
      SELECT token, COUNT(*) as cnt FROM device_tokens GROUP BY token HAVING COUNT(*) > 1;
    `;
    console.log('Duplicate tokens:', duplicates);
  } catch (e) {
    console.error('Error checking duplicates:', e);
  } finally {
    await prisma.$disconnect();
  }
})();
