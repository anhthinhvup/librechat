import { useForm } from 'react-hook-form';
import React, { useContext, useState } from 'react';
import { Turnstile } from '@marsidev/react-turnstile';
import { ThemeContext, Spinner, Button, isDark, Input, useToastContext } from '@librechat/client';
import { useNavigate, useOutletContext, useLocation } from 'react-router-dom';
import { useRegisterUserMutation } from 'librechat-data-provider/react-query';
import {
  useSendPhoneVerificationOTPMutation,
  useVerifyPhoneOTPMutation,
} from '~/data-provider';
import { useAuthContext } from '~/hooks';
import type { TRegisterUser, TError } from 'librechat-data-provider';
import type { TLoginLayoutContext } from '~/common';
import { useLocalize, TranslationKeys } from '~/hooks';
import { ErrorMessage } from './ErrorMessage';

const Registration: React.FC = () => {
  const navigate = useNavigate();
  const localize = useLocalize();
  const { theme } = useContext(ThemeContext);
  const { startupConfig, startupConfigError, isFetching } = useOutletContext<TLoginLayoutContext>();

  const {
    watch,
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<TRegisterUser>({ mode: 'onChange' });
  const password = watch('password');

  const [errorMessage, setErrorMessage] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [countdown, setCountdown] = useState<number>(3);
  const [turnstileToken, setTurnstileToken] = useState<string | null>(null);
  const [showPhoneVerification, setShowPhoneVerification] = useState<boolean>(false);
  const [registeredPhone, setRegisteredPhone] = useState<string>('');
  const [otpCode, setOtpCode] = useState<string>('');
  const [isVerifyingOTP, setIsVerifyingOTP] = useState<boolean>(false);
  const { showToast } = useToastContext();

  const location = useLocation();
  const queryParams = new URLSearchParams(location.search);
  const token = queryParams.get('token');
  const validTheme = isDark(theme) ? 'dark' : 'light';

  // only require captcha if we have a siteKey
  const requireCaptcha = Boolean(startupConfig?.turnstile?.siteKey);

  const { mutate: verifyOTPMutate } = useVerifyPhoneOTPMutation({
    onSuccess: (data) => {
      showToast({ message: data.message || 'Phone number verified successfully' });
      setIsVerifyingOTP(false);
      setShowPhoneVerification(false);
      setOtpCode('');
      // Navigate after verification
      navigate('/c/new', { replace: true });
    },
    onError: (error: any) => {
      showToast({
        message: error?.message || 'Failed to verify phone number',
        status: 'error',
      });
      setIsVerifyingOTP(false);
    },
  });

  const registerUser = useRegisterUserMutation({
    onMutate: () => {
      setIsSubmitting(true);
    },
    onSuccess: async (data, variables) => {
      setIsSubmitting(false);
      // Check if backend actually sent OTP (phoneVerificationRequired flag)
      // Only show verification dialog if OTP was sent
      const phoneVerificationRequired = (data as any)?.phoneVerificationRequired ?? false;
      
      // Get phone from form data (variables might not have phone after normalization)
      const formPhone = watch('phone');
      const phoneValue = variables.phone || formPhone;
      
      if (phoneValue && phoneValue.trim() !== '' && phoneVerificationRequired) {
        // OTP was sent, show verification dialog
        const normalizedPhone = phoneValue.replace(/\s/g, '');
        setRegisteredPhone(normalizedPhone);
        setShowPhoneVerification(true);
        setCountdown(0); // Don't auto-redirect
        showToast({
          message: 'Verification code has been sent to your phone. Please enter the code below.',
        });
      } else {
        // No phone or phone verification disabled, proceed with normal flow
        if (phoneValue && phoneValue.trim() !== '') {
          showToast({
            message: 'Registration successful! Phone number saved. You can verify it later in settings.',
          });
        }
        setCountdown(3);
        const timer = setInterval(() => {
          setCountdown((prevCountdown) => {
            if (prevCountdown <= 1) {
              clearInterval(timer);
              navigate('/c/new', { replace: true });
              return 0;
            } else {
              return prevCountdown - 1;
            }
          });
        }, 1000);
      }
    },
    onError: (error: unknown) => {
      setIsSubmitting(false);
      if ((error as TError).response?.data?.message) {
        setErrorMessage((error as TError).response?.data?.message ?? '');
      }
    },
  });

  const renderInput = (id: string, label: TranslationKeys, type: string, validation: object) => (
    <div className="mb-4">
      <div className="relative">
        <input
          id={id}
          type={type}
          autoComplete={id}
          aria-label={localize(label)}
          {...register(
            id as 'name' | 'email' | 'username' | 'password' | 'confirm_password' | 'phone',
            validation,
          )}
          aria-invalid={!!errors[id]}
          className="webkit-dark-styles transition-color peer w-full rounded-2xl border border-border-light bg-surface-primary px-3.5 pb-2.5 pt-3 text-text-primary duration-200 focus:border-green-500 focus:outline-none"
          placeholder=" "
          data-testid={id}
        />
        <label
          htmlFor={id}
          className="absolute start-3 top-1.5 z-10 origin-[0] -translate-y-4 scale-75 transform bg-surface-primary px-2 text-sm text-text-secondary-alt duration-200 peer-placeholder-shown:top-1/2 peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:scale-100 peer-focus:top-1.5 peer-focus:-translate-y-4 peer-focus:scale-75 peer-focus:px-2 peer-focus:text-green-500 rtl:peer-focus:left-auto rtl:peer-focus:translate-x-1/4"
        >
          {localize(label)}
        </label>
      </div>
      {errors[id] && (
        <span role="alert" className="mt-1 text-sm text-red-500">
          {String(errors[id]?.message) ?? ''}
        </span>
      )}
    </div>
  );

  return (
    <>
      {errorMessage && (
        <ErrorMessage>
          {localize('com_auth_error_create')} {errorMessage}
        </ErrorMessage>
      )}
      {registerUser.isSuccess && countdown > 0 && !showPhoneVerification && (
        <div
          className="rounded-md border border-green-500 bg-green-500/10 px-3 py-2 text-sm text-gray-600 dark:text-gray-200"
          role="alert"
        >
          {localize(
            startupConfig?.emailEnabled
              ? 'com_auth_registration_success_generic'
              : 'com_auth_registration_success_insecure',
          ) +
            ' ' +
            localize('com_auth_email_verification_redirecting', { 0: countdown.toString() })}
        </div>
      )}
      {registerUser.isSuccess && showPhoneVerification && (
        <div
          className="rounded-md border border-green-500 bg-green-500/10 px-3 py-2 text-sm text-gray-600 dark:text-gray-200"
          role="alert"
        >
          Registration successful! Please verify your phone number below.
        </div>
      )}
      {!startupConfigError && !isFetching && (
        <>
          <form
            className="mt-6"
            aria-label="Registration form"
            method="POST"
            onSubmit={handleSubmit((data: TRegisterUser) =>
              registerUser.mutate({ ...data, token: token ?? undefined }),
            )}
          >
            {renderInput('name', 'com_auth_full_name', 'text', {
              required: localize('com_auth_name_required'),
              minLength: {
                value: 3,
                message: localize('com_auth_name_min_length'),
              },
              maxLength: {
                value: 80,
                message: localize('com_auth_name_max_length'),
              },
            })}
            {renderInput('username', 'com_auth_username', 'text', {
              minLength: {
                value: 2,
                message: localize('com_auth_username_min_length'),
              },
              maxLength: {
                value: 80,
                message: localize('com_auth_username_max_length'),
              },
            })}
            {renderInput('email', 'com_auth_email', 'email', {
              required: localize('com_auth_email_required'),
              minLength: {
                value: 1,
                message: localize('com_auth_email_min_length'),
              },
              maxLength: {
                value: 120,
                message: localize('com_auth_email_max_length'),
              },
              pattern: {
                value: /\S+@\S+\.\S+/,
                message: localize('com_auth_email_pattern'),
              },
            })}
            {/* Phone field temporarily disabled - uncomment to enable */}
            {/* {renderInput('phone', 'com_auth_phone', 'tel', {
              required: false,
              pattern: {
                value: /^\+?[1-9]\d{1,14}$/,
                message: 'Invalid phone format. Use: +1234567890',
              },
            })} */}
            {showPhoneVerification && (
              <div className="mb-4 rounded-lg border border-blue-500 bg-blue-50 p-4 dark:bg-blue-900/20">
                <p className="mb-2 text-sm font-medium text-blue-900 dark:text-blue-200">
                  Verification code has been sent to {registeredPhone}
                </p>
                <div className="flex gap-2">
                  <Input
                    type="text"
                    value={otpCode}
                    onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                    placeholder="Enter 6-digit code"
                    disabled={isVerifyingOTP}
                    className="flex-1"
                    maxLength={6}
                  />
                  <Button
                    onClick={() => {
                      if (otpCode.length !== 6) {
                        showToast({ message: 'Please enter 6-digit code', status: 'error' });
                        return;
                      }
                      setIsVerifyingOTP(true);
                      // Get email from form
                      const formData = watch();
                      verifyOTPMutate({
                        phone: registeredPhone.replace(/\s/g, ''),
                        code: otpCode,
                        email: formData.email, // Include email for unauthenticated verification
                      });
                    }}
                    disabled={isVerifyingOTP || otpCode.length !== 6}
                    variant="default"
                  >
                    {isVerifyingOTP ? <Spinner /> : 'Verify'}
                  </Button>
                </div>
                <p className="mt-2 text-xs text-blue-700 dark:text-blue-300">
                  Please check your phone for the verification code. The code expires in 10 minutes.
                </p>
              </div>
            )}
            {renderInput('password', 'com_auth_password', 'password', {
              required: localize('com_auth_password_required'),
              minLength: {
                value: startupConfig?.minPasswordLength || 8,
                message: localize('com_auth_password_min_length'),
              },
              maxLength: {
                value: 128,
                message: localize('com_auth_password_max_length'),
              },
            })}
            {renderInput('confirm_password', 'com_auth_password_confirm', 'password', {
              validate: (value: string) =>
                value === password || localize('com_auth_password_not_match'),
            })}

            {startupConfig?.turnstile?.siteKey && (
              <div className="my-4 flex justify-center">
                <Turnstile
                  siteKey={startupConfig.turnstile.siteKey}
                  options={{
                    ...startupConfig.turnstile.options,
                    theme: validTheme,
                  }}
                  onSuccess={(token) => setTurnstileToken(token)}
                  onError={() => setTurnstileToken(null)}
                  onExpire={() => setTurnstileToken(null)}
                />
              </div>
            )}

            <div className="mt-6">
              <Button
                disabled={
                  Object.keys(errors).length > 0 ||
                  isSubmitting ||
                  (requireCaptcha && !turnstileToken)
                }
                type="submit"
                aria-label="Submit registration"
                variant="submit"
                className="h-12 w-full rounded-2xl"
              >
                {isSubmitting ? <Spinner /> : localize('com_auth_continue')}
              </Button>
            </div>
          </form>

          <p className="my-4 text-center text-sm font-light text-gray-700 dark:text-white">
            {localize('com_auth_already_have_account')}{' '}
            <a
              href="/login"
              aria-label="Login"
              className="inline-flex p-1 text-sm font-medium text-green-600 transition-colors hover:text-green-700 dark:text-green-400 dark:hover:text-green-300"
            >
              {localize('com_auth_login')}
            </a>
          </p>
        </>
      )}
    </>
  );
};

export default Registration;
