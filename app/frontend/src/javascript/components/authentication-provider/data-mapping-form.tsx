import React, { useEffect } from 'react';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import AuthProviderAPI from '../../api/auth-provider';
import { MappingFields } from '../../models/authentication-provider';
import { FormInput } from '../form/form-input';

export interface DataMappingFormProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
}

export const DataMappingForm = <TFieldValues extends FieldValues>({ register }: DataMappingFormProps<TFieldValues>) => {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [dataMapping, setDataMapping] = React.useState<MappingFields>(null);

  // fetch the mapping data from the API on mount
  useEffect(() => {
    AuthProviderAPI.mappingFields().then((data) => {
      setDataMapping(data);
    });
  }, []);

  return (
    <div className="data-mapping-form">
      <FormInput id="local_model" register={register} />
    </div>
  );
};
