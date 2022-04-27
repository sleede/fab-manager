import React from 'react';
import Select from 'react-select';
import { Controller, Path } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FieldPathValue, UnpackNestedValue } from 'react-hook-form/dist/types';
import { FormControlledComponent } from '../../models/form-component';
import { AbstractFormItem, AbstractFormItemProps } from './abstract-form-item';

interface FormSelectProps<TFieldValues, TContext extends object, TOptionValue> extends FormControlledComponent<TFieldValues, TContext>, AbstractFormItemProps<TFieldValues> {
  options: Array<selectOption<TOptionValue>>,
  valuesDefault?: Array<TOptionValue>,
  onChange?: (values: Array<TOptionValue>) => void,
  placeholder?: string,
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption<TOptionValue> = { value: TOptionValue, label: string };

/**
 * This component is a wrapper around react-select to use with react-hook-form.
 * It is a multi-select component.
 */
export const FormMultiSelect = <TFieldValues extends FieldValues, TContext extends object, TOptionValue>({ id, label, tooltip, className, control, placeholder, options, valuesDefault, error, rules, disabled, onChange, formState, readOnly, warning }: FormSelectProps<TFieldValues, TContext, TOptionValue>) => {
  /**
   * The following callback will trigger the onChange callback, if it was passed to this component,
   * when the selected option changes.
   */
  const onChangeCb = (newValues: Array<TOptionValue>): void => {
    if (typeof onChange === 'function') {
      onChange(newValues);
    }
  };

  return (
    <AbstractFormItem id={id} formState={formState} label={label}
                      className={`form-multi-select ${className}`} tooltip={tooltip}
                      disabled={disabled} readOnly={readOnly}
                      rules={rules} error={error} warning={warning}>
        <Controller name={id as FieldPath<TFieldValues>}
                    control={control}
                    defaultValue={valuesDefault as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>}
                    render={({ field: { onChange, value, ref } }) =>
                      <Select ref={ref}
                              classNamePrefix="rs"
                              className="rs"
                              value={options.filter(c => value?.includes(c.value))}
                              onChange={val => {
                                const values = val?.map(c => c.value);
                                onChangeCb(values);
                                onChange(values);
                              }}
                              placeholder={placeholder}
                              options={options}
                              isMulti />
                    } />
    </AbstractFormItem>
  );
};
