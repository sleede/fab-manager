import React from 'react';
import { FormControlledComponent } from '../../models/form-component';
import { AbstractFormItem, AbstractFormItemProps } from './abstract-form-item';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FabTextEditor } from '../base/text-editor/fab-text-editor';
import { Controller, Path } from 'react-hook-form';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FieldPathValue, UnpackNestedValue } from 'react-hook-form/dist/types';

interface FormRichTextProps<TFieldValues, TContext extends object> extends FormControlledComponent<TFieldValues, TContext>, AbstractFormItemProps<TFieldValues> {
  valueDefault?: string,
  limit?: number,
  paragraphTools?: boolean,
  video?: boolean,
  image?: boolean,
}

/**
 * THis component is a rich-text editor to use with react-hook-form.
 */
export const FormRichText = <TFieldValues extends FieldValues, TContext extends object>({ id, label, tooltip, className, control, valueDefault, error, warning, rules, disabled, formState, limit, paragraphTools, video, image }: FormRichTextProps<TFieldValues, TContext>) => {
  return (
    <AbstractFormItem id={id} label={label} tooltip={tooltip}
                      className={`form-rich-text ${className || ''}`}
                      error={error} warning={warning} rules={rules}
                      disabled={disabled} formState={formState}>
      <Controller name={id as FieldPath<TFieldValues>}
                  control={control}
                  defaultValue={valueDefault as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>}
                  render={({ field: { onChange, value } }) =>
        <FabTextEditor onChange={onChange} content={value} limit={limit} paragraphTools={paragraphTools} video={video} image={image} />
      } />
    </AbstractFormItem>
  );
};
