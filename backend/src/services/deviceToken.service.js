const prisma = require('../config/prisma');

/**
 * Register or update a device token for a user.
 * If a token already exists for the user, it will be updated with the new platform.
 */
async function registerToken(userId, token, platform) {
  if (!userId || !token || !platform) {
    throw new Error('Missing required parameters');
  }
  return await prisma.deviceToken.upsert({
    where: { token },
    update: { userId, platform },
    create: { userId, token, platform },
  });
}

/**
 * Remove a device token for a user.
 */
async function removeToken(userId, token) {
  if (!userId || !token) {
    throw new Error('Missing required parameters');
  }
  return await prisma.deviceToken.deleteMany({
    where: { userId, token },
  });
}

/**
 * List all tokens for a user (optional utility).
 */
async function listTokens(userId) {
  return await prisma.deviceToken.findMany({
    where: { userId },
    select: { token: true, platform: true },
  });
}

module.exports = { registerToken, removeToken, listTokens };
