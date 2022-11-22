import React, { ReactNode } from 'react';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormComponent, FormControlledComponent } from '../../models/form-component';
import { AbstractFormItemProps } from './abstract-form-item';
import { UseFormSetValue } from 'react-hook-form/dist/types/form';
import { ArrayPath, FieldArray, Path, useFieldArray, useWatch } from 'react-hook-form';
import { FormImageUpload } from './form-image-upload';
import { FabButton } from '../base/fab-button';
import { Plus } from 'phosphor-react';
import { ImageType } from '../../models/file';
import { UnpackNestedValue } from 'react-hook-form/dist/types';
import { FieldPathValue } from 'react-hook-form/dist/types/path';

interface FormMultiImageUploadProps<TFieldValues, TContext extends object> extends FormComponent<TFieldValues>, FormControlledComponent<TFieldValues, TContext>, AbstractFormItemProps<TFieldValues> {
  setValue: UseFormSetValue<TFieldValues>,
  addButtonLabel: ReactNode
}

/**
 * This component allows to upload multiple images, in forms managed by react-hook-form.
 */
export const FormMultiImageUpload = <TFieldValues extends FieldValues, TContext extends object>({ id, className, register, control, setValue, formState, addButtonLabel }: FormMultiImageUploadProps<TFieldValues, TContext>) => {
  const { append } = useFieldArray({ control, name: id as ArrayPath<TFieldValues> });
  const output = useWatch({ control, name: id as Path<TFieldValues> });

  /**
   * Add new image, set as main if it is the first
   */
  const addImage = () => {
    append({
      is_main: output.filter(i => i.is_main).length === 0,
      _destroy: false
    } as UnpackNestedValue<FieldArray<TFieldValues, ArrayPath<TFieldValues>>>);
  };

  /**
   * Remove an image and set the first image as the new main image if the provided was main
   */
  const handleRemoveImage = (image: ImageType, index: number) => {
    return () => {
      if (image.is_main && output.length > 1) {
        setValue(
          `${id}.${index === 0 ? 1 : 0}.is_main` as Path<TFieldValues>,
          true as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
        );
      }
      setValue(
        `${id}.${index}._destroy` as Path<TFieldValues>,
        true as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
      );
    };
  };

  /**
   * Set the image at the given index as the new main image, and unset the current main image
   */
  const handleSetMainImage = (index: number) => {
    return (setNewImageValue) => {
      const mainImageIndex = output.findIndex(i => i.is_main && i !== index);
      if (mainImageIndex > -1) {
        setValue(
          `${id}.${mainImageIndex}.is_main` as Path<TFieldValues>,
          false as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
        );
      }
      setNewImageValue(true);
    };
  };

  return (
    <div className={`form-multi-image-upload ${className || ''}`}>
      <div className="list">
        {output.map((field: ImageType, index) => (
          <FormImageUpload key={index}
            defaultImage={field}
            id={`${id}.${index}`}
            accept="image/*"
            size="small"
            register={register}
            control={control}
            setValue={setValue}
            formState={formState}
            className={field._destroy ? 'hidden' : ''}
            onFileRemove={handleRemoveImage(field, index)}
            onFileIsMain={handleSetMainImage(index)}
            mainOption
          />
        ))}
      </div>
      <FabButton
        onClick={addImage}
        className='is-secondary'
        icon={<Plus size={24} />}>
        {addButtonLabel}
      </FabButton>
    </div>
  );
};
