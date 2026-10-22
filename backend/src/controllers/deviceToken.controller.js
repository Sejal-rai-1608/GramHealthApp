const { registerToken, removeToken } = require('../services/deviceToken.service');
const { authenticate } = require('../middleware/auth.middleware');

// POST /api/device-tokens
async function register(req, res) {
  try {
    const userId = req.user.id; // set by authenticate
    const { token, platform } = req.body;
    const saved = await registerToken(userId, token, platform);
    return res.json({ success: true, data: saved });
  } catch (err) {
    console.error('[DeviceTokenController] Register error:', err);
    return res.status(500).json({ success: false, message: err.message });
  }
}

// DELETE /api/device-tokens/:token
async function remove(req, res) {
  try {
    const userId = req.user.id;
    const { token } = req.params;
    await removeToken(userId, token);
    return res.json({ success: true, message: 'Token removed' });
  } catch (err) {
    console.error('[DeviceTokenController] Remove error:', err);
    return res.status(500).json({ success: false, message: err.message });
  }
}

module.exports = { register, remove };
