const { logger } = require('@librechat/data-schemas');
const axios = require('axios');

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
 * Send SMS via HTTP API (Generic provider)
 * Supports any SMS gateway with HTTP API
 * @param {string} to - Phone number to send to (E.164 format)
 * @param {string} message - Message content
 * @returns {Promise<{success: boolean, messageId?: string, error?: string}>}
 */
const sendViaHTTP = async (to, message) => {
  try {
    const apiUrl = process.env.SMS_HTTP_API_URL;
    const apiKey = process.env.SMS_HTTP_API_KEY;
    const apiSecret = process.env.SMS_HTTP_API_SECRET;
    const fromNumber = process.env.SMS_HTTP_FROM_NUMBER || process.env.SMS_HTTP_FROM;

    if (!apiUrl) {
      return { success: false, error: 'SMS_HTTP_API_URL not configured' };
    }

    // Support different HTTP methods and formats
    const method = (process.env.SMS_HTTP_METHOD || 'POST').toUpperCase();
    const requestFormat = process.env.SMS_HTTP_FORMAT || 'json'; // json, form, query

    // Build request data based on format
    let requestData = {};
    let headers = {
      'Content-Type': requestFormat === 'json' ? 'application/json' : 'application/x-www-form-urlencoded',
    };

    // Add authentication
    if (apiKey) {
      if (process.env.SMS_HTTP_AUTH_TYPE === 'header') {
        const authHeader = process.env.SMS_HTTP_AUTH_HEADER || 'Authorization';
        const authFormat = process.env.SMS_HTTP_AUTH_FORMAT || 'Bearer'; // Bearer, Basic, ApiKey
        if (authFormat === 'Bearer') {
          headers[authHeader] = `Bearer ${apiKey}`;
        } else if (authFormat === 'ApiKey') {
          headers[authHeader] = apiKey;
        } else if (authFormat === 'Basic' && apiSecret) {
          const credentials = Buffer.from(`${apiKey}:${apiSecret}`).toString('base64');
          headers[authHeader] = `Basic ${credentials}`;
        }
      } else {
        // Add to request body/query
        requestData[process.env.SMS_HTTP_API_KEY_FIELD || 'api_key'] = apiKey;
        if (apiSecret) {
          requestData[process.env.SMS_HTTP_API_SECRET_FIELD || 'api_secret'] = apiSecret;
        }
      }
    }

    // Map phone and message fields (customizable)
    const toField = process.env.SMS_HTTP_TO_FIELD || 'to';
    const messageField = process.env.SMS_HTTP_MESSAGE_FIELD || 'message';
    const fromField = process.env.SMS_HTTP_FROM_FIELD || 'from';

    requestData[toField] = to;
    requestData[messageField] = message;
    if (fromNumber) {
      requestData[fromField] = fromNumber;
    }

    // Make HTTP request
    const config = {
      method,
      url: apiUrl,
      headers,
      timeout: parseInt(process.env.SMS_HTTP_TIMEOUT || '10000', 10),
    };

    if (method === 'GET' || requestFormat === 'query') {
      config.params = requestData;
    } else if (requestFormat === 'json') {
      config.data = requestData;
    } else {
      // form-urlencoded
      const formData = Object.keys(requestData)
        .map((key) => `${encodeURIComponent(key)}=${encodeURIComponent(requestData[key])}`)
        .join('&');
      config.data = formData;
    }

    const response = await axios(config);

    // Extract message ID from response (customizable)
    const messageIdField = process.env.SMS_HTTP_MESSAGE_ID_FIELD || 'message_id';
    let messageId = null;

    if (response.data) {
      if (typeof response.data === 'string') {
        try {
          const parsed = JSON.parse(response.data);
          messageId = parsed[messageIdField] || parsed.id || parsed.messageId || response.data;
        } catch {
          messageId = response.data;
        }
      } else {
        messageId = response.data[messageIdField] || response.data.id || response.data.messageId;
      }
    }

    // Check success (customizable)
    const successField = process.env.SMS_HTTP_SUCCESS_FIELD || 'status';
    const successValue = process.env.SMS_HTTP_SUCCESS_VALUE || 'success';
    let isSuccess = false;

    if (response.data) {
      const data = typeof response.data === 'string' ? JSON.parse(response.data) : response.data;
      const status = data[successField] || data.status || response.status;
      isSuccess = status === successValue || status === 'ok' || status === 200 || response.status === 200;
    } else {
      isSuccess = response.status >= 200 && response.status < 300;
    }

    if (isSuccess) {
      logger.info(`[SMSService] SMS sent via HTTP API to ${to}, MessageId: ${messageId || 'N/A'}`);
      return { success: true, messageId: messageId || 'http-sent' };
    } else {
      const errorMsg = response.data?.error || response.data?.message || 'Unknown error';
      return { success: false, error: errorMsg };
    }
  } catch (error) {
    logger.error(`[SMSService] HTTP API error:`, error);
    return {
      success: false,
      error: error.response?.data?.message || error.message || 'Failed to send SMS via HTTP API',
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
    // Try HTTP API first if configured (most flexible)
    if (process.env.SMS_HTTP_API_URL) {
      const result = await sendViaHTTP(to, message);
      if (result.success) {
        return result;
      }
    }

    // Try Twilio if credentials are available
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
      error: 'No SMS provider configured. Please set up HTTP API, Twilio, or AWS SNS.',
    };
  }

  // Use specified provider
  if (smsProvider === 'http' || smsProvider === 'custom') {
    return await sendViaHTTP(to, message);
  }

  if (smsProvider === 'twilio') {
    return await sendViaTwilio(to, message);
  }

  if (smsProvider === 'aws' || smsProvider === 'sns') {
    return await sendViaSNS(to, message);
  }

  return {
    success: false,
    error: `Unknown SMS provider: ${smsProvider}. Use 'http', 'custom', 'twilio', 'aws', 'sns', or 'auto'`,
  };
};

module.exports = {
  sendSMS,
  sendViaTwilio,
  sendViaSNS,
  sendViaHTTP,
  initializeTwilio,
  initializeSNS,
};

