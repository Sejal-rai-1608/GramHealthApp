const { Pool } = require("pg");
const { PrismaPg } = require("@prisma/adapter-pg");
const { PrismaClient } = require("@prisma/client");

const isLocal =
  process.env.DB_HOST === "localhost" ||
  process.env.DB_HOST === "127.0.0.1" ||
  process.env.NODE_ENV !== "production";

let pool;

if (isLocal) {
  // Local development / Docker — SSL disabled
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: false,
  });
} else {
  // Production on Render / Cloud
  const sslConfig = process.env.DATABASE_CA_CERT
    ? { ca: process.env.DATABASE_CA_CERT, rejectUnauthorized: true }
    : { rejectUnauthorized: false };

  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: sslConfig,
  });
}

const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

module.exports = prisma;