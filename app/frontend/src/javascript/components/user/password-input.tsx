import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import { FormInput } from '../form/form-input';
import { FormState } from 'react-hook-form/dist/types/form';
import { PasswordStrength } from './password-strength';
import * as React from 'react';
import { useState } from 'react';
import { Eye, EyeSlash } from 'phosphor-react';

interface PasswordInputProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  currentFormPassword: string,
  formState: FormState<TFieldValues>,
}

/**
 * Passwords inputs: new password and confirmation.
 */
export const PasswordInput = <TFieldValues extends FieldValues>({ register, currentFormPassword, formState }: PasswordInputProps<TFieldValues>) => {
  const { t } = useTranslation('shared');

  const [password, setPassword] = useState<string>(null);
  const [inputType, setInputType] = useState<'password'|'text'>('password');

  /**
   * Callback triggered when the user types a password
   */
  const handlePasswordChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPassword(event.target.value);
  };

  /**
   * Switch the password characters between hidden and displayed
   */
  const toggleShowPassword = () => {
    if (inputType === 'text') {
      setInputType('password');
    } else {
      setInputType('text');
    }
  };

  return (
    <div className="password-input">
      <FormInput id="password" register={register}
                 addOn={inputType === 'password' ? <Eye size={24} /> : <EyeSlash size={24} />}
                 addOnAction={toggleShowPassword}
                 rules={{
                   required: true,
                   validate: (value: string) => {
                     if (value.length < 12) {
                       return t('app.shared.password_input.password_too_short') as string;
                     }
                     return true;
                   }
                 }}
                 formState={formState}
                 onChange={handlePasswordChange}
                 label={t('app.shared.password_input.new_password')}
                 tooltip={t('app.shared.password_input.help')}
                 type={inputType} />
      <PasswordStrength password={password} />
      <FormInput id="password_confirmation"
                 register={register}
                 rules={{
                   required: true,
                   validate: (value: string) => {
                     if (value !== currentFormPassword) {
                       return t('app.shared.password_input.confirmation_mismatch') as string;
                     }
                     return true;
                   }
                 }}
                 formState={formState}
                 label={t('app.shared.password_input.confirm_password')}
                 type="password" />
    </div>
  );
};
