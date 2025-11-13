const { logger } = require('@librechat/data-schemas');
const { findUser, updateUser } = require('~/models');
const crypto = require('crypto');

/**
 * Generate OTP code (6 digits)
 * @returns {string}
 */
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Send OTP via SMS
 * @param {string} phone - Phone number
 * @param {string} code - OTP code
 * @returns {Promise<void>}
 */
const sendSMS = async (phone, code) => {
  // TODO: Integrate with SMS service (Twilio, AWS SNS, etc.)
  // For now, just log the OTP (for testing)
  logger.info(`[sendSMS] OTP for ${phone}: ${code}`);
  
  // Example with Twilio (uncomment and configure):
  /*
  const twilio = require('twilio');
  const client = twilio(
    process.env.TWILIO_ACCOUNT_SID,
    process.env.TWILIO_AUTH_TOKEN
  );
  
  await client.messages.create({
    body: `Your LibreChat verification code is: ${code}`,
    to: phone,
    from: process.env.TWILIO_PHONE_NUMBER,
  });
  */
  
  // Example with AWS SNS (uncomment and configure):
  /*
  const AWS = require('aws-sdk');
  const sns = new AWS.SNS({
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: process.env.AWS_REGION || 'us-east-1',
  });
  
  await sns.publish({
    PhoneNumber: phone,
    Message: `Your LibreChat verification code is: ${code}`,
  }).promise();
  */
};

/**
 * Send phone verification OTP
 * @param {ServerRequest} req
 * @returns {Promise<{status: number, message: string}>}
 */
const sendPhoneVerificationOTP = async (req) => {
  try {
    const { phone } = req.body;
    const userId = req.user?._id;

    if (!phone) {
      return { status: 400, message: 'Phone number is required' };
    }

    // Validate phone format (basic validation)
    const phoneRegex = /^\+?[1-9]\d{1,14}$/;
    if (!phoneRegex.test(phone.replace(/\s/g, ''))) {
      return { status: 400, message: 'Invalid phone number format' };
    }

    // Normalize phone number (remove spaces, ensure + prefix)
    const normalizedPhone = phone.replace(/\s/g, '').startsWith('+') 
      ? phone.replace(/\s/g, '') 
      : `+${phone.replace(/\s/g, '')}`;

    // Check if phone is already used by another user
    const existingUser = await findUser({ phone: normalizedPhone }, 'phone _id');
    if (existingUser && existingUser._id.toString() !== userId?.toString()) {
      return { status: 400, message: 'Phone number already in use' };
    }

    // Generate OTP
    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Hash OTP for storage
    const otpHash = crypto.createHash('sha256').update(otp).digest('hex');

    // Update or create user with phone and OTP
    if (userId) {
      await updateUser(userId, {
        phone: normalizedPhone,
        phoneVerificationCode: otpHash,
        phoneVerificationExpires: expiresAt,
        phoneVerified: false,
      });
    } else {
      // For registration, store in session or return error
      return { status: 401, message: 'User not authenticated' };
    }

    // Send OTP via SMS
    await sendSMS(normalizedPhone, otp);

    logger.info(`[sendPhoneVerificationOTP] OTP sent to ${normalizedPhone}`);

    return {
      status: 200,
      message: 'Verification code sent to your phone',
    };
  } catch (error) {
    logger.error(`[sendPhoneVerificationOTP] Error: ${error.message}`);
    return {
      status: 500,
      message: 'Something went wrong',
    };
  }
};

/**
 * Verify phone OTP
 * @param {ServerRequest} req
 * @returns {Promise<{status: number, message: string}>}
 */
const verifyPhoneOTP = async (req) => {
  try {
    const { phone, code } = req.body;
    const userId = req.user?._id;

    if (!phone || !code) {
      return { status: 400, message: 'Phone number and code are required' };
    }

    // Normalize phone number
    const normalizedPhone = phone.replace(/\s/g, '').startsWith('+') 
      ? phone.replace(/\s/g, '') 
      : `+${phone.replace(/\s/g, '')}`;

    // Find user
    const user = await findUser(
      { _id: userId, phone: normalizedPhone },
      'phone phoneVerificationCode phoneVerificationExpires phoneVerified'
    );

    if (!user) {
      return { status: 404, message: 'User or phone number not found' };
    }

    if (user.phoneVerified) {
      return { status: 200, message: 'Phone already verified' };
    }

    // Check if OTP exists and not expired
    if (!user.phoneVerificationCode || !user.phoneVerificationExpires) {
      return { status: 400, message: 'No verification code found. Please request a new code.' };
    }

    if (new Date() > user.phoneVerificationExpires) {
      return { status: 400, message: 'Verification code expired. Please request a new code.' };
    }

    // Verify OTP
    const codeHash = crypto.createHash('sha256').update(code).digest('hex');
    if (codeHash !== user.phoneVerificationCode) {
      return { status: 400, message: 'Invalid verification code' };
    }

    // Update user as verified
    await updateUser(userId, {
      phoneVerified: true,
      phoneVerificationCode: null,
      phoneVerificationExpires: null,
    });

    logger.info(`[verifyPhoneOTP] Phone verified for ${normalizedPhone}`);

    return {
      status: 200,
      message: 'Phone number verified successfully',
    };
  } catch (error) {
    logger.error(`[verifyPhoneOTP] Error: ${error.message}`);
    return {
      status: 500,
      message: 'Something went wrong',
    };
  }
};

module.exports = {
  sendPhoneVerificationOTP,
  verifyPhoneOTP,
};

