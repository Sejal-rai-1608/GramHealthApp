const { Pool } = require("pg");
const { PrismaPg } = require("@prisma/adapter-pg");
const { PrismaClient } = require("@prisma/client");

const isLocal = process.env.DB_HOST === "localhost" || process.env.DB_HOST === "127.0.0.1";

let pool;

if (isLocal) {
    // Local Docker / dev — explicitly disable SSL
    pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: false,
    });
} else {
    // Cloud (Aiven etc.) — SSL with CA cert
    const fs = require("fs");
    const path = require("path");
    const caPath = path.join(__dirname, "../../certs/ca.pem");

    pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: {
            ca: fs.readFileSync(caPath, "utf8"),
            rejectUnauthorized: true,
        },
    });
}

const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

module.exports = prisma;