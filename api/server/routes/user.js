const express = require('express');
const {
  updateUserPluginsController,
  resendVerificationController,
  getTermsStatusController,
  acceptTermsController,
  verifyEmailController,
  deleteUserController,
  getUserController,
  sendPhoneVerificationController,
  verifyPhoneController,
} = require('~/server/controllers/UserController');
const { requireJwtAuth, canDeleteAccount, verifyEmailLimiter } = require('~/server/middleware');

const router = express.Router();

router.get('/', requireJwtAuth, getUserController);
router.get('/terms', requireJwtAuth, getTermsStatusController);
router.post('/terms/accept', requireJwtAuth, acceptTermsController);
router.post('/plugins', requireJwtAuth, updateUserPluginsController);
router.delete('/delete', requireJwtAuth, canDeleteAccount, deleteUserController);
router.post('/verify', verifyEmailController);
router.post('/verify/resend', verifyEmailLimiter, resendVerificationController);
router.post('/phone/send-otp', requireJwtAuth, sendPhoneVerificationController);
// Allow phone verification without JWT if email is provided (for registration flow)
router.post('/phone/verify', verifyPhoneController);

module.exports = router;
