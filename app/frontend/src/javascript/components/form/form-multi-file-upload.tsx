import React, { ReactNode } from 'react';
import { FormFileUpload } from './form-file-upload';
import { FabButton } from '../base/fab-button';
import { Plus } from 'phosphor-react';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormComponent, FormControlledComponent } from '../../models/form-component';
import { AbstractFormItemProps } from './abstract-form-item';
import { UseFormSetValue } from 'react-hook-form/dist/types/form';
import { ArrayPath, FieldArray, useFieldArray } from 'react-hook-form';
import { FileType } from '../../models/file';
import { UnpackNestedValue } from 'react-hook-form/dist/types';

interface FormMultiFileUploadProps<TFieldValues, TContext extends object> extends FormComponent<TFieldValues>, FormControlledComponent<TFieldValues, TContext>, AbstractFormItemProps<TFieldValues> {
  setValue: UseFormSetValue<TFieldValues>,
  addButtonLabel: ReactNode,
  accept: string
}

/**
 * This component allows to upload multiple files, in forms managed by react-hook-form.
 */
export const FormMultiFileUpload = <TFieldValues extends FieldValues, TContext extends object>({ id, className, register, control, setValue, formState, addButtonLabel, accept }: FormMultiFileUploadProps<TFieldValues, TContext>) => {
  const { fields, append, remove } = useFieldArray({ control, name: id as ArrayPath<TFieldValues> });

  return (
    <div className={`form-multi-file-upload ${className || ''}`}>
      <div className="list">
        {fields.map((field: FileType, index) => (
          <FormFileUpload key={field.id}
            defaultFile={field}
            id={`${id}.${index}`}
            accept={accept}
            register={register}
            setValue={setValue}
            formState={formState}
            className={field._destroy ? 'hidden' : ''}
            onFileRemove={() => remove(index)}/>
        ))}
      </div>
      <FabButton
        onClick={() => append({ _destroy: false } as UnpackNestedValue<FieldArray<TFieldValues, ArrayPath<TFieldValues>>>)}
        className='is-secondary'
        icon={<Plus size={24} />}>
        {addButtonLabel}
      </FabButton>
    </div>
  );
};
