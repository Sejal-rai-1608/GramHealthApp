// src/socket/callEvents.js
// Socket.IO event handlers for incoming‑call signaling (Phase 2)
// No database writes – only validation & event forwarding.

const prisma = require('../config/prisma');
const { getProfileIdForRole } = require('../utils/profile');

module.exports = (io) => {
  // Helper: verify that the authenticated socket user participates in the consultation
  const verifyParticipation = async (user, consultationId) => {
    const consultation = await prisma.consultation.findUnique({
      where: { id: consultationId },
      select: {
        patientId: true,
        doctorId: true,
        ashaWorkerId: true,
      },
    });
    if (!consultation) {
      throw new Error('Consultation not found');
    }
    const profileId = await getProfileIdForRole(user.role, user.id);
    const isParticipant =
      (user.role === 'PATIENT' && consultation.patientId === profileId) ||
      (user.role === 'DOCTOR' && consultation.doctorId === profileId) ||
      (user.role === 'ASHA' && consultation.ashaWorkerId === profileId);
    if (!isParticipant) {
      throw new Error('User not authorized for this consultation');
    }
    return consultation;
  };

  io.on('connection', (socket) => {
    // Join a private user room for direct messages if needed
    const userRoom = `user:${socket.user.id}`;
    socket.join(userRoom);

    // ---------------------------------------------------------------------
    // 1️⃣ joinRoom – client asks to listen to a specific consultation
    // ---------------------------------------------------------------------
    socket.on('joinRoom', async ({ consultationId }) => {
      try {
        await verifyParticipation(socket.user, consultationId);
        const room = `consultation_${consultationId}`;
        socket.join(room);
        socket.emit('joinedRoom', { consultationId, room });
      } catch (err) {
        socket.emit('error', { message: err.message });
      }
    });

    // ---------------------------------------------------------------------
    // 2️⃣ callInvite – patient invites the doctor to a video call
    // ---------------------------------------------------------------------
    socket.on('callInvite', async ({ consultationId }) => {
      try {
        // Only a patient may send an invite
        if (socket.user.role !== 'PATIENT') {
          throw new Error('Only patients can invite a doctor');
        }
        await verifyParticipation(socket.user, consultationId);
        const room = `consultation_${consultationId}`;
        // Broadcast to everyone in the room (doctor will be joined as well)
        io.to(room).emit('callInvite', { consultationId, from: socket.user.id });
      } catch (err) {
        socket.emit('error', { message: err.message });
      }
    });

    // ---------------------------------------------------------------------
    // 3️⃣ callCancel – either participant can cancel the pending call
    // ---------------------------------------------------------------------
    socket.on('callCancel', async ({ consultationId }) => {
      try {
        await verifyParticipation(socket.user, consultationId);
        const room = `consultation_${consultationId}`;
        io.to(room).emit('callCancel', { consultationId, by: socket.user.id });
      } catch (err) {
        socket.emit('error', { message: err.message });
      }
    });

    // ---------------------------------------------------------------------
    // Clean up on disconnect – rooms are auto‑cleaned by Socket.IO.
    // ---------------------------------------------------------------------
    socket.on('disconnect', () => {
      // No special logic needed; just log for debugging.
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });
};
