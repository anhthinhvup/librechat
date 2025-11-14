const { logger } = require('@librechat/data-schemas');
const { findUser, updateUser } = require('~/models');
const { sendSMS } = require('./SMSService');
const crypto = require('crypto');

/**
 * Generate a 6-digit OTP code
 * @returns {string}
 */
const generateOTP = () => {
  return crypto.randomInt(100000, 999999).toString();
};

/**
 * Send Phone Verification OTP
 * @param {ServerRequest} req
 * @returns {Promise<{status: number, message: string}>}
 */
const sendPhoneVerificationOTP = async (req) => {
  try {
    const { phone } = req.body;
    const userId = req.user._id;

    if (!phone) {
      return { status: 400, message: 'Phone number is required' };
    }

    // Normalize phone number (ensure it starts with +)
    const normalizedPhone = phone.startsWith('+') ? phone : `+${phone}`;

    // Check if phone is already verified by another user
    const existingUser = await findUser({ phone: normalizedPhone, phoneVerified: true });
    if (existingUser && existingUser._id.toString() !== userId.toString()) {
      return { status: 400, message: 'This phone number is already verified by another account' };
    }

    // Generate OTP
    const otpCode = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Save OTP to user
    await updateUser(userId, {
      phone: normalizedPhone,
      phoneVerificationCode: otpCode,
      phoneVerificationExpires: expiresAt,
      phoneVerified: false,
    });

    // Send OTP via SMS
    const smsMessage = `Your ${process.env.APP_TITLE || 'LibreChat'} verification code is: ${otpCode}. This code expires in 10 minutes.`;
    const smsResult = await sendSMS(normalizedPhone, smsMessage);

    if (!smsResult.success) {
      logger.error(`[sendPhoneVerificationOTP] Failed to send SMS: ${smsResult.error}`);
      
      // In development, still return success with OTP in response
      const isDevelopment = process.env.NODE_ENV !== 'production';
      if (isDevelopment) {
        logger.warn(`[sendPhoneVerificationOTP] Development mode - OTP: ${otpCode}`);
        return {
          status: 200,
          message: `Verification code generated. OTP: ${otpCode} (Development mode - SMS not configured)`,
          otp: otpCode,
        };
      }

      // In production, return error if SMS fails
      return {
        status: 500,
        message: 'Failed to send verification code. Please try again later.',
      };
    }

    logger.info(`[sendPhoneVerificationOTP] OTP sent successfully to ${normalizedPhone} via SMS`);

    // In development, also include OTP in response for testing
    const isDevelopment = process.env.NODE_ENV !== 'production';
    return {
      status: 200,
      message: 'Verification code sent successfully. Please check your phone.',
      ...(isDevelopment && { otp: otpCode }), // Include OTP in dev mode for testing
    };
  } catch (error) {
    logger.error('[sendPhoneVerificationOTP]', error);
    return { status: 500, message: 'Failed to send verification code' };
  }
};

/**
 * Verify Phone OTP
 * @param {ServerRequest} req
 * @returns {Promise<{status: number, message: string}>}
 */
const verifyPhoneOTP = async (req) => {
  try {
    const { phone, code } = req.body;
    const userId = req.user._id;

    if (!phone || !code) {
      return { status: 400, message: 'Phone number and verification code are required' };
    }

    // Normalize phone number
    const normalizedPhone = phone.startsWith('+') ? phone : `+${phone}`;

    // Get user with verification code (use + to include fields with select: false)
    const user = await findUser(
      { _id: userId },
      '_id phone phoneVerified +phoneVerificationCode +phoneVerificationExpires',
    );

    if (!user) {
      return { status: 404, message: 'User not found' };
    }

    // Check if phone matches
    if (user.phone !== normalizedPhone) {
      return { status: 400, message: 'Phone number does not match' };
    }

    // Check if OTP exists and not expired
    if (!user.phoneVerificationCode || !user.phoneVerificationExpires) {
      return { status: 400, message: 'No verification code found. Please request a new code.' };
    }

    if (new Date() > user.phoneVerificationExpires) {
      return { status: 400, message: 'Verification code has expired. Please request a new code.' };
    }

    // Verify OTP
    if (user.phoneVerificationCode !== code) {
      return { status: 400, message: 'Invalid verification code' };
    }

    // Mark phone as verified and clear OTP
    await updateUser(userId, {
      phoneVerified: true,
      phoneVerificationCode: undefined,
      phoneVerificationExpires: undefined,
    });

    logger.info(`[verifyPhoneOTP] Phone verified for user ${userId}: ${normalizedPhone}`);

    return {
      status: 200,
      message: 'Phone number verified successfully',
    };
  } catch (error) {
    logger.error('[verifyPhoneOTP]', error);
    return { status: 500, message: 'Failed to verify phone number' };
  }
};

module.exports = {
  sendPhoneVerificationOTP,
  verifyPhoneOTP,
};

