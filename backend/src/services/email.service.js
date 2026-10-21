const nodemailer = require("nodemailer");

const createTransporter = () => {
  const host = (process.env.SMTP_HOST || "smtp.gmail.com").trim();
  const port = parseInt((process.env.SMTP_PORT || "587").trim());
  const secure = port === 465;
  const user = (process.env.SMTP_USER || "").trim();
  const pass = (process.env.SMTP_PASS || "").trim();

  if (!user || !pass) {
    console.warn("[EmailService] SMTP credentials not configured. Emails will be logged instead of sent.");
    return null;
  }

  console.log(`[EmailService] Creating transporter: ${host}:${port} (secure: ${secure}) user: ${user ? 'SET' : 'MISSING'}`);

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: { user, pass },
    tls: {
      rejectUnauthorized: process.env.NODE_ENV === "production"
    },
    // Connection timeouts for Render/network issues
    connectionTimeout: 10000, // 10 seconds
    greetingTimeout: 5000,
    socketTimeout: 10000
  });
};

const sendOtpEmail = async (email, otp, name = "User") => {
  const transporter = createTransporter();

  if (!transporter) {
    console.log(`[EmailService] [DEV MODE] SMTP not configured. OTP for ${email}: ${otp}`);
    return { success: true, devMode: true };
  }

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #2E7D32 0%, #4CAF50 100%); padding: 30px; border-radius: 12px 12px 0 0; text-align: center;">
        <h1 style="color: white; margin: 0; font-size: 28px;">GramHealth</h1>
        <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0;">Password Reset Verification</p>
      </div>
      <div style="background: #ffffff; padding: 40px 30px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 12px 12px;">
        <h2 style="color: #2E7D32; margin-top: 0; font-size: 24px;">Password Reset Request</h2>
        <p style="font-size: 16px; color: #555;">Hi <strong>${name}</strong>,</p>
        <p>You requested to reset your GramHealth account password. Use the verification code below to proceed:</p>
        <div style="background: #f1f8e9; border: 2px dashed #4CAF50; border-radius: 12px; padding: 20px; text-align: center; margin: 30px 0;">
          <span style="font-size: 36px; font-weight: 700; color: #2E7D32; letter-spacing: 8px; font-family: 'Courier New', monospace;">${otp}</span>
        </div>
        <p style="color: #666; font-size: 14px;">This code will expire in <strong>10 minutes</strong>.</p>
        <p style="color: #666; font-size: 14px;">If you didn't request a password reset, please ignore this email or contact support if you have concerns.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        <p style="color: #999; font-size: 12px; text-align: center;">&copy; ${new Date().getFullYear()} GramHealth. All rights reserved.</p>
      </div>
    </body>
    </html>
  `;

  const text = `
GramHealth - Password Reset Verification

Hi ${name},

You requested to reset your GramHealth account password. Use the verification code below to proceed:

Verification Code: ${otp}

This code will expire in 10 minutes.

If you didn't request this, please ignore this email or contact support if you have concerns.

© ${new Date().getFullYear()} GramHealth. All rights reserved.
  `;

  try {
    console.log(`[EmailService] Sending OTP email to ${email} via ${process.env.SMTP_HOST}:${process.env.SMTP_PORT}`);
    
    const info = await transporter.sendMail({
      from: `"GramHealth" <${process.env.SMTP_USER}>`,
      to: email,
      subject: "GramHealth - Password Reset Verification Code",
      text,
      html
    });

    console.log(`[EmailService] OTP email sent to ${email}: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error("[EmailService] Failed to send OTP email:", error);
    console.error("[EmailService] Error details:", error.message, error.code, error.response);
    // Don't throw - we don't want to break the forgot password flow if email fails
    return { success: false, error: error.message, code: error.code, response: error.response };
  }
};

const sendWelcomeEmail = async (email, name) => {
  try {
    const transporter = createTransporter();
    
    if (!transporter) {
      return { success: true, devMode: true };
    }

    await transporter.sendMail({
      from: `"GramHealth" <${process.env.SMTP_USER}>`,
      to: email,
      subject: "Welcome to GramHealth!",
      text: `Hi ${name},\n\nWelcome to GramHealth! We're excited to have you on board.\n\n- The GramHealth Team`,
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #2E7D32 0%, #4CAF50 100%); padding: 30px; border-radius: 12px 12px 0 0; text-align: center;">
            <h1 style="color: white; margin: 0;">Welcome to GramHealth!</h1>
          </div>
          <div style="padding: 30px; background: #f9f9f9; border-radius: 0 0 12px 12px;">
            <h2 style="color: #2E7D32;">Hi ${name},</h2>
            <p>Welcome to GramHealth! We're excited to have you on board.</p>
            <p>Your health journey starts here. Explore our features:</p>
            <ul style="color: #555;">
              <li>Teleconsultation with qualified doctors</li>
              <li>Health records management</li>
              <li>Medicine delivery</li>
              <li>Emergency assistance</li>
            </ul>
          </div>
        </div>
      `
    });
    
    return { success: true };
  } catch (error) {
    console.error("[EmailService] Failed to send welcome email:", error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  sendOtpEmail,
  sendWelcomeEmail
};