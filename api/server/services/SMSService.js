const { logger } = require('@librechat/data-schemas');

let twilioClient = null;
let snsClient = null;

/**
 * Initialize Twilio client
 */
const initializeTwilio = () => {
  try {
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;

    if (!accountSid || !authToken) {
      logger.warn('[SMSService] Twilio credentials not configured');
      return null;
    }

    // Lazy load Twilio to avoid requiring it if not configured
    const twilio = require('twilio');
    twilioClient = twilio(accountSid, authToken);
    logger.info('[SMSService] Twilio client initialized');
    return twilioClient;
  } catch (error) {
    logger.error('[SMSService] Failed to initialize Twilio:', error);
    return null;
  }
};

/**
 * Initialize AWS SNS client
 */
const initializeSNS = () => {
  try {
    const region = process.env.AWS_SNS_REGION || process.env.AWS_REGION || 'us-east-1';
    const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
    const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;

    if (!accessKeyId || !secretAccessKey) {
      logger.warn('[SMSService] AWS SNS credentials not configured');
      return null;
    }

    // Lazy load AWS SDK
    const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
    snsClient = new SNSClient({
      region,
      credentials: {
        accessKeyId,
        secretAccessKey,
      },
    });
    logger.info(`[SMSService] AWS SNS client initialized for region: ${region}`);
    return snsClient;
  } catch (error) {
    logger.error('[SMSService] Failed to initialize AWS SNS:', error);
    return null;
  }
};

/**
 * Send SMS via Twilio
 * @param {string} to - Phone number to send to (E.164 format)
 * @param {string} message - Message content
 * @returns {Promise<{success: boolean, messageId?: string, error?: string}>}
 */
const sendViaTwilio = async (to, message) => {
  try {
    if (!twilioClient) {
      twilioClient = initializeTwilio();
    }

    if (!twilioClient) {
      return { success: false, error: 'Twilio not configured' };
    }

    const fromNumber = process.env.TWILIO_PHONE_NUMBER;
    if (!fromNumber) {
      return { success: false, error: 'TWILIO_PHONE_NUMBER not configured' };
    }

    const result = await twilioClient.messages.create({
      body: message,
      from: fromNumber,
      to: to,
    });

    logger.info(`[SMSService] SMS sent via Twilio to ${to}, SID: ${result.sid}`);
    return { success: true, messageId: result.sid };
  } catch (error) {
    logger.error(`[SMSService] Twilio error:`, error);
    return {
      success: false,
      error: error.message || 'Failed to send SMS via Twilio',
    };
  }
};

/**
 * Send SMS via AWS SNS
 * @param {string} to - Phone number to send to (E.164 format)
 * @param {string} message - Message content
 * @returns {Promise<{success: boolean, messageId?: string, error?: string}>}
 */
const sendViaSNS = async (to, message) => {
  try {
    if (!snsClient) {
      snsClient = initializeSNS();
    }

    if (!snsClient) {
      return { success: false, error: 'AWS SNS not configured' };
    }

    const { PublishCommand } = require('@aws-sdk/client-sns');
    const command = new PublishCommand({
      PhoneNumber: to,
      Message: message,
      MessageAttributes: {
        'AWS.SNS.SMS.SMSType': {
          DataType: 'String',
          StringValue: 'Transactional', // Use 'Promotional' for marketing messages
        },
      },
    });

    const result = await snsClient.send(command);
    logger.info(`[SMSService] SMS sent via AWS SNS to ${to}, MessageId: ${result.MessageId}`);
    return { success: true, messageId: result.MessageId };
  } catch (error) {
    logger.error(`[SMSService] AWS SNS error:`, error);
    return {
      success: false,
      error: error.message || 'Failed to send SMS via AWS SNS',
    };
  }
};

/**
 * Send SMS using the configured provider
 * Priority: TWILIO > AWS_SNS > Log (development)
 * @param {string} to - Phone number to send to (E.164 format)
 * @param {string} message - Message content
 * @returns {Promise<{success: boolean, messageId?: string, error?: string}>}
 */
const sendSMS = async (to, message) => {
  const smsProvider = process.env.SMS_PROVIDER?.toLowerCase() || 'auto';

  // Auto-detect provider based on available credentials
  if (smsProvider === 'auto') {
    // Try Twilio first if credentials are available
    if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
      const result = await sendViaTwilio(to, message);
      if (result.success) {
        return result;
      }
    }

    // Try AWS SNS if credentials are available
    if (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
      const result = await sendViaSNS(to, message);
      if (result.success) {
        return result;
      }
    }

    // Fallback to logging in development
    const isDevelopment = process.env.NODE_ENV !== 'production';
    if (isDevelopment) {
      logger.info(`[SMSService] Development mode - SMS would be sent to ${to}: ${message}`);
      return { success: true, messageId: 'dev-mode' };
    }

    return {
      success: false,
      error: 'No SMS provider configured. Please set up Twilio or AWS SNS.',
    };
  }

  // Use specified provider
  if (smsProvider === 'twilio') {
    return await sendViaTwilio(to, message);
  }

  if (smsProvider === 'aws' || smsProvider === 'sns') {
    return await sendViaSNS(to, message);
  }

  return {
    success: false,
    error: `Unknown SMS provider: ${smsProvider}. Use 'twilio', 'aws', 'sns', or 'auto'`,
  };
};

module.exports = {
  sendSMS,
  sendViaTwilio,
  sendViaSNS,
  initializeTwilio,
  initializeSNS,
};

