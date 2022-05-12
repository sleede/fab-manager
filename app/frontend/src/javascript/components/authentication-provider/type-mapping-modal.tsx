import React from 'react';
import { FabModal } from '../base/fab-modal';
import { useTranslation } from 'react-i18next';
import { IntegerMappingForm } from './integer-mapping-form';
import { UseFormRegister } from 'react-hook-form';
import { Control } from 'react-hook-form/dist/types/form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { mappingType } from '../../models/authentication-provider';
import { BooleanMappingForm } from './boolean-mapping-form';
import { DateMappingForm } from './date-mapping-form';
import { StringMappingForm } from './string-mapping-form';

interface TypeMappingModalProps<TFieldValues, TContext extends object> {
  model: string,
  field: string,
  type: mappingType,
  isOpen: boolean,
  toggleModal: () => void,
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues, TContext>,
  fieldMappingId: number,
}

/**
 * Modal dialog to display the expected type for the current data field.
 * Also allows to map the incoming data (from the authentication provider API) to the expected type/data.
 *
 * This component is intended to be used in a react-hook-form context.
 */
export const TypeMappingModal = <TFieldValues extends FieldValues, TContext extends object>({ model, field, type, isOpen, toggleModal, register, control, fieldMappingId }:TypeMappingModalProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('admin');

  return (
    <FabModal isOpen={isOpen}
              toggleModal={toggleModal}
              className="type-mapping-modal"
              title={t('app.admin.authentication.type_mapping_modal.data_mapping')}
              confirmButton={<i className="fa fa-check" />}
              onConfirm={toggleModal}>
      <span>{model} &gt; {field} ({t('app.admin.authentication.type_mapping_modal.TYPE_expected', { TYPE: t(`app.admin.authentication.type_mapping_modal.types.${type}`) })})</span>
      {type === 'integer' && <IntegerMappingForm register={register} control={control} fieldMappingId={fieldMappingId} />}
      {type === 'boolean' && <BooleanMappingForm register={register} fieldMappingId={fieldMappingId} />}
      {type === 'date' && <DateMappingForm control={control} fieldMappingId={fieldMappingId} />}
      {type === 'string' && <StringMappingForm register={register} control={control} fieldMappingId={fieldMappingId} />}
    </FabModal>
  );
};
