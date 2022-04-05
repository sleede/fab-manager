import React, { SelectHTMLAttributes } from 'react';
import Select from 'react-select';
import { Controller, Path } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FieldPathValue, UnpackNestedValue } from 'react-hook-form/dist/types';
import { FormControlledComponent } from '../../models/form-component';

interface FormSelectProps<TFieldValues, TContext extends object, TOptionValue> extends SelectHTMLAttributes<HTMLSelectElement>, FormControlledComponent<TFieldValues, TContext> {
  id: string,
  label?: string,
  options: Array<selectOption<TOptionValue>>,
  valueDefault?: TOptionValue,
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption<TOptionValue> = { value: TOptionValue, label: string };

/**
 * This component is a wrapper for react-select to use with react-hook-form
 */
export const FormSelect = <TFieldValues extends FieldValues, TContext extends object, TOptionValue>({ id, label, className, control, placeholder, options, valueDefault, error, rules, disabled }: FormSelectProps<TFieldValues, TContext, TOptionValue>) => {
  const classNames = `
    form-item ${className || ''}
    ${error && error[id] ? 'is-incorrect' : ''}
    ${rules && rules.required ? 'is-required' : ''}
    ${disabled ? 'is-disabled' : ''}`;

  return (
    <label className={classNames}>
      {label && <div className="form-item-header">
        <p>{label}</p>
      </div>}
      <div className="form-item-field">
        <Controller name={id as FieldPath<TFieldValues>}
                    control={control}
                    defaultValue={valueDefault as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>}
                    render={({ field: { onChange, value, ref } }) =>
          <Select inputRef={ref}
                  classNamePrefix="rs"
                  className="rs"
                  value={options.find(c => c.value === value)}
                  onChange={val => onChange(val.value)}
                  placeholder={placeholder}
                  options={options} />
        } />
      </div>
    </label>
  );
};
