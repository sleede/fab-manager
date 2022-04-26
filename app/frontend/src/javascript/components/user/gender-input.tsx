import React from 'react';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { useTranslation } from 'react-i18next';

interface GenderInputProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
}

/**
 * Input component to set the gender for the user
 */
export const GenderInput = <TFieldValues extends FieldValues>({ register }: GenderInputProps<TFieldValues>) => {
  const { t } = useTranslation('shared');

  return (
    <div className="gender-input">
      <label>
        <p>{t('app.shared.gender_input.man')}</p>
        <input type="radio"
               value="true"
               {...register('statistic_profile_attributes.gender' as FieldPath<TFieldValues>)} />
      </label>
      <label>
        <p>{t('app.shared.gender_input.woman')}</p>
        <input type="radio"
               value="false"
               {...register('statistic_profile_attributes.gender' as FieldPath<TFieldValues>)} />
      </label>
    </div>
  );
};
