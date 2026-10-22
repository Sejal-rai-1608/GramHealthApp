// src/socket/callEvents.js
// Socket.IO event handlers for incoming‑call signaling (Phase 2)
// No database writes – only validation & event forwarding.

const prisma = require('../config/prisma');
const { getProfileIdForRole } = require('../utils/profile');
const { v4: uuidv4 } = require('uuid');

const JITSI_DOMAIN = process.env.JITSI_DOMAIN || "meet.jit.si";
const JITSI_SERVER_URL = `https://${JITSI_DOMAIN}`;

const generateJitsiRoomName = (consultationId) => {
  const prefix = "gramhealth";
  const shortId = consultationId.replace(/-/g, "").substring(0, 12);
  const randomSuffix = Math.random().toString(36).substring(2, 8);
  return `${prefix}-${shortId}-${randomSuffix}`;
};

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

  // Helper: ensure Jitsi meeting details exist for a consultation, generating them if missing
  const ensureJitsiDetails = async (consultationId) => {
    let consultation = await prisma.consultation.findUnique({
      where: { id: consultationId },
      select: { jitsiRoomName: true, jitsiServerUrl: true },
    });
    if (!consultation?.jitsiRoomName || !consultation?.jitsiServerUrl) {
      const jitsiRoomName = generateJitsiRoomName(consultationId);
      consultation = await prisma.consultation.update({
        where: { id: consultationId },
        data: { jitsiRoomName, jitsiServerUrl: JITSI_SERVER_URL },
        select: { jitsiRoomName: true, jitsiServerUrl: true },
      });
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
    // 4️⃣ callAccept – doctor accepts the call invitation
    // ---------------------------------------------------------------------
    socket.on('callAccept', async ({ consultationId }) => {
      try {
        await verifyParticipation(socket.user, consultationId);
        const room = `consultation_${consultationId}`;
        // Ensure Jitsi meeting details exist (generate if missing) so both
        // parties receive valid room/server URLs via the callAccept event.
        const consultation = await ensureJitsiDetails(consultationId);
        io.to(room).emit('callAccept', {
          consultationId,
          by: socket.user.id,
          jitsiRoomName: consultation.jitsiRoomName,
          jitsiServerUrl: consultation.jitsiServerUrl,
        });
      } catch (err) {
        socket.emit('error', { message: err.message });
      }
    });

    // ---------------------------------------------------------------------
    // 5️⃣ callReject – doctor rejects the call invitation
    // ---------------------------------------------------------------------
    socket.on('callReject', async ({ consultationId }) => {
      try {
        await verifyParticipation(socket.user, consultationId);
        const room = `consultation_${consultationId}`;
        io.to(room).emit('callReject', { consultationId, by: socket.user.id });
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
