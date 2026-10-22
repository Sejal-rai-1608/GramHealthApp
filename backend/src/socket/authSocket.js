// src/socket/authSocket.js
// Socket.io authentication middleware – mirrors the HTTP auth.middleware logic
// It validates the JWT supplied in `socket.handshake.auth.token` and attaches
// `socket.user` with the decoded payload and minimal user data from the DB.

const jwt = require('jsonwebtoken');
const prisma = require('../config/prisma');

const authSocket = async (socket, next) => {
  try {
    const token = socket.handshake.auth?.token;
    if (!token) {
      return next(new Error('Authentication token missing'));
    }

    const secret = process.env.JWT_SECRET || 'gramhealth-fallback-secret-key';
    const decoded = jwt.verify(token, secret);

    // The HTTP middleware stores the full user record; we replicate the essential fields.
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, role: true, name: true, email: true, phone: true },
    });

    if (!user) {
      return next(new Error('User not found'));
    }

    // Attach a simplified user object to the socket for later checks.
    socket.user = {
      id: user.id,
      role: user.role,
      name: user.name,
      email: user.email,
      phone: user.phone,
    };
    next();
  } catch (err) {
    // jwt throws various error names – treat all as authentication failures.
    return next(new Error('Invalid or expired token'));
  }
};

module.exports = authSocket;
