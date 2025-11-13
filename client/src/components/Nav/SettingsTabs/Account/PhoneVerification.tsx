import React, { useCallback, useState } from 'react';
import { useSetRecoilState } from 'recoil';
import { PhoneIcon } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  OGDialog,
  useToastContext,
  OGDialogContent,
  OGDialogHeader,
  OGDialogTitle,
  Button,
  Input,
  Spinner,
} from '@librechat/client';
import type { TUser } from 'librechat-data-provider';
import {
  useSendPhoneVerificationOTPMutation,
  useVerifyPhoneOTPMutation,
} from '~/data-provider';
import { useAuthContext, useLocalize } from '~/hooks';
import store from '~/store';

type Phase = 'input' | 'verify';

const phaseVariants = {
  initial: { opacity: 0, scale: 0.95 },
  animate: { opacity: 1, scale: 1, transition: { duration: 0.3, ease: 'easeOut' } },
  exit: { opacity: 0, scale: 0.95, transition: { duration: 0.3, ease: 'easeIn' } },
};

const PhoneVerification: React.FC = () => {
  const localize = useLocalize();
  const { user } = useAuthContext();
  const setUser = useSetRecoilState(store.user);
  const { showToast } = useToastContext();

  const [phone, setPhone] = useState<string>(user?.phone || '');
  const [code, setCode] = useState<string>('');
  const [isDialogOpen, setDialogOpen] = useState<boolean>(false);
  const [phase, setPhase] = useState<Phase>(user?.phone && !user?.phoneVerified ? 'verify' : 'input');

  const { mutate: sendOTPMutate, isLoading: isSending } = useSendPhoneVerificationOTPMutation();
  const { mutate: verifyOTPMutate, isLoading: isVerifying } = useVerifyPhoneOTPMutation();

  const resetState = useCallback(() => {
    setCode('');
    setPhase(user?.phone && !user?.phoneVerified ? 'verify' : 'input');
  }, [user]);

  const handleSendOTP = useCallback(() => {
    if (!phone.trim()) {
      showToast({ message: 'Please enter a phone number', status: 'error' });
      return;
    }

    sendOTPMutate(
      { phone: phone.trim() },
      {
        onSuccess: () => {
          showToast({ message: 'Verification code sent to your phone' });
          setPhase('verify');
        },
        onError: (error: any) => {
          showToast({
            message: error?.response?.data?.message || 'Failed to send verification code',
            status: 'error',
          });
        },
      },
    );
  }, [phone, sendOTPMutate, showToast]);

  const handleVerify = useCallback(() => {
    if (!code.trim() || code.trim().length !== 6) {
      showToast({ message: 'Please enter a valid 6-digit code', status: 'error' });
      return;
    }

    verifyOTPMutate(
      { phone: phone.trim(), code: code.trim() },
      {
        onSuccess: () => {
          showToast({ message: 'Phone number verified successfully' });
          setDialogOpen(false);
          setUser(
            (prev) =>
              ({
                ...prev,
                phone: phone.trim(),
                phoneVerified: true,
              }) as TUser,
          );
          resetState();
        },
        onError: (error: any) => {
          showToast({
            message: error?.response?.data?.message || 'Invalid verification code',
            status: 'error',
          });
        },
      },
    );
  }, [phone, code, verifyOTPMutate, showToast, setUser, resetState]);

  const handleResend = useCallback(() => {
    handleSendOTP();
  }, [handleSendOTP]);

  return (
    <OGDialog
      open={isDialogOpen}
      onOpenChange={(open) => {
        setDialogOpen(open);
        if (!open) {
          resetState();
        }
      }}
    >
      <div className="flex items-center justify-between rounded-lg border border-border-light bg-surface-primary p-4">
        <div className="flex items-center gap-3">
          <PhoneIcon className="h-5 w-5 text-text-secondary" />
          <div>
            <div className="font-medium text-text-primary">Phone Verification</div>
            <div className="text-sm text-text-secondary">
              {user?.phoneVerified
                ? `Verified: ${user.phone}`
                : user?.phone
                  ? `Unverified: ${user.phone}`
                  : 'No phone number added'}
            </div>
          </div>
        </div>
        <Button
          variant="outline"
          onClick={() => setDialogOpen(true)}
          className="h-9 px-4"
        >
          {user?.phoneVerified ? 'Update' : user?.phone ? 'Verify' : 'Add Phone'}
        </Button>
      </div>

      <OGDialogContent className="w-11/12 max-w-lg p-6">
        <AnimatePresence mode="wait">
          <motion.div
            key={phase}
            variants={phaseVariants}
            initial="initial"
            animate="animate"
            exit="exit"
            className="space-y-6"
          >
            <OGDialogHeader>
              <OGDialogTitle className="mb-2 flex items-center gap-3 text-2xl font-bold">
                <PhoneIcon className="h-6 w-6 text-primary" />
                {user?.phoneVerified ? 'Update Phone Number' : 'Verify Phone Number'}
              </OGDialogTitle>
            </OGDialogHeader>

            <AnimatePresence mode="wait">
              {phase === 'input' && (
                <motion.div
                  key="input"
                  variants={phaseVariants}
                  initial="initial"
                  animate="animate"
                  exit="exit"
                  className="space-y-4"
                >
                  <div>
                    <label className="mb-2 block text-sm font-medium text-text-primary">
                      Phone Number
                    </label>
                    <Input
                      type="tel"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="+1234567890"
                      className="w-full"
                      disabled={isSending}
                    />
                    <p className="mt-1 text-xs text-text-secondary">
                      Enter your phone number with country code (e.g., +84123456789)
                    </p>
                  </div>
                  <Button
                    onClick={handleSendOTP}
                    disabled={!phone.trim() || isSending}
                    className="w-full"
                    variant="submit"
                  >
                    {isSending ? <Spinner /> : 'Send Verification Code'}
                  </Button>
                </motion.div>
              )}

              {phase === 'verify' && (
                <motion.div
                  key="verify"
                  variants={phaseVariants}
                  initial="initial"
                  animate="animate"
                  exit="exit"
                  className="space-y-4"
                >
                  <div>
                    <label className="mb-2 block text-sm font-medium text-text-primary">
                      Verification Code
                    </label>
                    <Input
                      type="text"
                      value={code}
                      onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                      placeholder="000000"
                      className="w-full text-center text-2xl tracking-widest"
                      maxLength={6}
                      disabled={isVerifying}
                    />
                    <p className="mt-1 text-xs text-text-secondary">
                      Enter the 6-digit code sent to {phone || user?.phone}
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <Button
                      onClick={handleResend}
                      disabled={isSending}
                      variant="outline"
                      className="flex-1"
                    >
                      {isSending ? <Spinner /> : 'Resend Code'}
                    </Button>
                    <Button
                      onClick={handleVerify}
                      disabled={code.trim().length !== 6 || isVerifying}
                      className="flex-1"
                      variant="submit"
                    >
                      {isVerifying ? <Spinner /> : 'Verify'}
                    </Button>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        </AnimatePresence>
      </OGDialogContent>
    </OGDialog>
  );
};

export default React.memo(PhoneVerification);

