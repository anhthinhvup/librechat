import React, { useState, useCallback } from 'react';
import { useSetRecoilState } from 'recoil';
import { PhoneIcon } from 'lucide-react';
import {
  Button,
  Input,
  useToastContext,
} from '@librechat/client';
import type { TUser } from 'librechat-data-provider';
import {
  useSendPhoneVerificationOTPMutation,
  useVerifyPhoneOTPMutation,
} from '~/data-provider';
import { useAuthContext, useLocalize } from '~/hooks';
import store from '~/store';

const PhoneVerification: React.FC = () => {
  const localize = useLocalize();
  const { user } = useAuthContext();
  const setUser = useSetRecoilState(store.user);
  const { showToast } = useToastContext();

  const [phone, setPhone] = useState<string>(user?.phone || '');
  const [otpCode, setOtpCode] = useState<string>('');
  const [isSendingOTP, setIsSendingOTP] = useState<boolean>(false);
  const [isVerifying, setIsVerifying] = useState<boolean>(false);
  const [showOTPInput, setShowOTPInput] = useState<boolean>(false);

  const { mutate: sendOTPMutate } = useSendPhoneVerificationOTPMutation();
  const { mutate: verifyOTPMutate } = useVerifyPhoneOTPMutation({
    onSuccess: (data) => {
      showToast({ message: data.message || 'Phone number verified successfully' });
      setShowOTPInput(false);
      setOtpCode('');
      // Refresh user data
      if (user) {
        setUser({ ...user, phoneVerified: true, phone: phone });
      }
    },
    onError: (error: any) => {
      showToast({
        message: error?.message || 'Failed to verify phone number',
        status: 'error',
      });
    },
  });

  const handleSendOTP = useCallback(() => {
    if (!phone || phone.trim() === '') {
      showToast({ message: 'Please enter a phone number', status: 'error' });
      return;
    }

    // Basic phone validation
    const phoneRegex = /^\+?[1-9]\d{1,14}$/;
    if (!phoneRegex.test(phone.replace(/\s/g, ''))) {
      showToast({
        message: 'Invalid phone number format. Use format: +1234567890',
        status: 'error',
      });
      return;
    }

    setIsSendingOTP(true);
    sendOTPMutate(
      { phone: phone.replace(/\s/g, '') },
      {
        onSuccess: (data) => {
          showToast({
            message: data.message || 'Verification code sent successfully',
          });
          setShowOTPInput(true);
          setIsSendingOTP(false);
        },
        onError: (error: any) => {
          showToast({
            message: error?.message || 'Failed to send verification code',
            status: 'error',
          });
          setIsSendingOTP(false);
        },
      },
    );
  }, [phone, sendOTPMutate, showToast]);

  const handleVerifyOTP = useCallback(() => {
    if (!otpCode || otpCode.trim() === '') {
      showToast({ message: 'Please enter the verification code', status: 'error' });
      return;
    }

    if (otpCode.length !== 6) {
      showToast({ message: 'Verification code must be 6 digits', status: 'error' });
      return;
    }

    setIsVerifying(true);
    verifyOTPMutate(
      {
        phone: phone.replace(/\s/g, ''),
        code: otpCode,
      },
      {
        onSuccess: () => {
          setIsVerifying(false);
        },
        onError: () => {
          setIsVerifying(false);
        },
      },
    );
  }, [phone, otpCode, verifyOTPMutate, showToast]);

  const isPhoneVerified = user?.phoneVerified === true;
  const hasPhone = user?.phone && user.phone.trim() !== '';

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center gap-2">
        <PhoneIcon className="h-5 w-5" />
        <span className="font-medium">Phone Verification</span>
        {isPhoneVerified && (
          <span className="text-xs text-green-600 dark:text-green-400">(Verified)</span>
        )}
      </div>

      {!isPhoneVerified && (
        <div className="flex flex-col gap-2">
          <div className="flex gap-2">
            <Input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+1234567890"
              disabled={isSendingOTP || isVerifying}
              className="flex-1"
            />
            <Button
              onClick={handleSendOTP}
              disabled={isSendingOTP || isVerifying || !phone}
              variant="default"
            >
              {isSendingOTP ? 'Sending...' : 'Send Code'}
            </Button>
          </div>

          {showOTPInput && (
            <div className="flex gap-2">
              <Input
                type="text"
                value={otpCode}
                onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                placeholder="Enter 6-digit code"
                disabled={isVerifying}
                className="flex-1"
                maxLength={6}
              />
              <Button
                onClick={handleVerifyOTP}
                disabled={isVerifying || otpCode.length !== 6}
                variant="default"
              >
                {isVerifying ? 'Verifying...' : 'Verify'}
              </Button>
            </div>
          )}
        </div>
      )}

      {isPhoneVerified && hasPhone && (
        <div className="text-sm text-text-secondary">
          Verified phone: {user.phone}
        </div>
      )}
    </div>
  );
};

export default React.memo(PhoneVerification);

