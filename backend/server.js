require("dotenv").config();

const app = require("./src/app");
const prisma = require("./src/config/prisma");

const PORT = process.env.PORT || 5000;

const startServer = async () => {
    try {
        await prisma.$queryRaw`SELECT 1`;

        console.log("PostgreSQL connected successfully");
        console.log("Prisma connected successfully");

        app.listen(PORT, () => {
            console.log(`GramHealth server running on port ${PORT}`);
        });

    } catch (error) {
        console.error("Database connection failed:");
        console.error(error);

        process.exit(1);
    }
};

// GramHealth backend server
startServer();