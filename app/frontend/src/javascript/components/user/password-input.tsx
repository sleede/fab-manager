import React from 'react';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import { FormInput } from '../form/form-input';
import { FormState } from 'react-hook-form/dist/types/form';

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

  return (
    <div className="password-input">
      <FormInput id="password" register={register}
                 rules={{
                   required: true,
                   validate: (value: string) => {
                     if (value.length < 8) {
                       return t('app.shared.password_input.password_too_short') as string;
                     }
                     return true;
                   }
                 }}
                 formState={formState}
                 label={t('app.shared.password_input.new_password')}
                 type="password" />
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
