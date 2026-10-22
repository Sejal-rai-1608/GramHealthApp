// Duplicate‑token check – read‑only utility script
// Uses the Prisma client configured in src/config/prisma.js (adapter‑based)
require('dotenv').config(); // Load .env like the server does
const prisma = require('./src/config/prisma'); // Existing Prisma client with adapter

;(async () => {
  try {
    const duplicates = await prisma.$queryRaw`
      SELECT token, COUNT(*) AS cnt
      FROM device_tokens
      GROUP BY token
      HAVING COUNT(*) > 1;
    `;

    if (duplicates.length === 0) {
      console.log('✅ No duplicate device tokens found.');
    } else {
      console.log('⚠️ Duplicate device tokens detected:');
      console.table(duplicates);
    }
  } catch (err) {
    console.error('❌ Error while checking duplicates:', err.message);
  } finally {
    await prisma.$disconnect();
  }
})();

