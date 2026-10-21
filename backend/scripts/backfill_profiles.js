require("dotenv").config({ path: require("path").join(__dirname, "../.env") });

const prisma = require("../src/config/prisma");

async function main() {
    const users = await prisma.user.findMany({
        select: { id: true, role: true, name: true, email: true }
    });

    console.log(`Found ${users.length} users. Backfilling profiles...\n`);

    let created = 0;
    let skipped = 0;

    for (const user of users) {
        try {
            if (user.role === "PATIENT") {
                const existing = await prisma.patient.findUnique({ where: { userId: user.id } });
                if (!existing) {
                    await prisma.patient.create({ data: { userId: user.id } });
                    console.log(`  ✅ Created Patient profile: ${user.name} (${user.email})`);
                    created++;
                } else {
                    console.log(`  ⏭  Patient already exists: ${user.name}`);
                    skipped++;
                }
            } else if (user.role === "DOCTOR") {
                const existing = await prisma.doctor.findUnique({ where: { userId: user.id } });
                if (!existing) {
                    await prisma.doctor.create({ data: { userId: user.id } });
                    console.log(`  ✅ Created Doctor profile: ${user.name} (${user.email})`);
                    created++;
                } else {
                    console.log(`  ⏭  Doctor already exists: ${user.name}`);
                    skipped++;
                }
            } else if (user.role === "ASHA") {
                const existing = await prisma.ashaWorker.findUnique({ where: { userId: user.id } });
                if (!existing) {
                    await prisma.ashaWorker.create({ data: { userId: user.id } });
                    console.log(`  ✅ Created AshaWorker profile: ${user.name} (${user.email})`);
                    created++;
                } else {
                    console.log(`  ⏭  AshaWorker already exists: ${user.name}`);
                    skipped++;
                }
            } else {
                console.log(`  ⏭  ADMIN — no sub-table needed: ${user.name}`);
                skipped++;
            }
        } catch (err) {
            console.error(`  ❌ Failed for ${user.name} (${user.email}): ${err.message}`);
        }
    }

    console.log(`\n✅ Done! Created: ${created}  |  Skipped/Already existed: ${skipped}`);
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
