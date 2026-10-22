require('dotenv').config();

const http = require('http');
const { Server } = require('socket.io');
const app = require('./src/app');
const prisma = require('./src/config/prisma');
const authSocket = require('./src/socket/authSocket');
const callEvents = require('./src/socket/callEvents');

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    // Verify DB connection
    await prisma.$queryRaw`SELECT 1`;
    console.log('PostgreSQL connected successfully');
    console.log('Prisma connected successfully');

    // Create HTTP server and attach Socket.IO
    const httpServer = http.createServer(app);
    const io = new Server(httpServer, {
      cors: {
        // Allow mobile apps (no origin) and restrict in production as needed
        origin: (origin, callback) => {
          if (!origin) return callback(null, true);
          // TODO: replace "*" with specific domains for production
          return callback(null, true);
        },
        credentials: true,
        methods: ['GET', 'POST']
      }
    });

    // Authenticate socket connections using existing JWT logic
    io.use(authSocket);

    // Register call‑signaling event handlers
    callEvents(io);

    // Expose io to Express routes if needed
    app.set('io', io);

    httpServer.listen(PORT, '0.0.0.0', () => {
      console.log(`GramHealth server (HTTP+Socket.IO) running on port ${PORT} (0.0.0.0)`);
    });
  } catch (error) {
    console.error('Database connection failed:');
    console.error(error);
    process.exit(1);
  }
};

// Start the server
startServer();
