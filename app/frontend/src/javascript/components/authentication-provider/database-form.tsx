import React from 'react';
import { FormInput } from '../form/form-input';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';

interface DatabaseFormProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
}

/**
 * Partial form to fill the settings for a new/existing database provider.
 */
export const DatabaseForm = <TFieldValues extends FieldValues>({ register }: DatabaseFormProps<TFieldValues>) => {
  return (
    <div className="database-form">
      <FormInput id="providable_attributes.id"
                 register={register}
                 type="hidden" />
    </div>
  );
};
