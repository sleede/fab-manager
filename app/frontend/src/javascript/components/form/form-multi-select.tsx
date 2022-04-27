import React, { ReactNode } from 'react';
import Select from 'react-select';
import { Controller, Path } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FieldPathValue, UnpackNestedValue } from 'react-hook-form/dist/types';
import { FormControlledComponent } from '../../models/form-component';

interface FormSelectProps<TFieldValues, TContext extends object, TOptionValue> extends FormControlledComponent<TFieldValues, TContext> {
  id: string,
  label?: string,
  tooltip?: ReactNode,
  options: Array<selectOption<TOptionValue>>,
  valuesDefault?: Array<TOptionValue>,
  onChange?: (values: Array<TOptionValue>) => void,
  className?: string,
  placeholder?: string,
  disabled?: boolean,
  expectedResult?: 'array' | 'string'
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
export const FormMultiSelect = <TFieldValues extends FieldValues, TContext extends object, TOptionValue>({ id, label, tooltip, className, control, placeholder, options, valuesDefault, error, rules, disabled, onChange, expectedResult }: FormSelectProps<TFieldValues, TContext, TOptionValue>) => {
  const classNames = [
    'form-multi-select form-item',
    `${className || ''}`,
    `${error && error[id] ? 'is-incorrect' : ''}`,
    `${rules && rules.required ? 'is-required' : ''}`,
    `${disabled ? 'is-disabled' : ''}`
  ].join(' ');

  /**
   * The following callback will trigger the onChange callback, if it was passed to this component,
   * when the selected option changes.
   * It will also update the react-hook-form's value, according to the provided 'result' property (string or array).
   */
  const onChangeCb = (newValues: Array<TOptionValue>, rhfOnChange): void => {
    if (typeof onChange === 'function') {
      onChange(newValues);
    }
    if (expectedResult === 'string') {
      rhfOnChange(newValues.join(','));
    } else {
      rhfOnChange(newValues);
    }
  };

  /**
   * This function will return the currently selected options, according to the provided react-hook-form's value.
   */
  const getCurrentValues = (value: Array<TOptionValue>|string): Array<selectOption<TOptionValue>> => {
    let values: Array<TOptionValue> = [];
    if (typeof value === 'string') {
      values = value.split(',') as Array<unknown> as Array<TOptionValue>;
    } else {
      values = value;
    }
    return options.filter(c => values?.includes(c.value));
  };

  return (
    <label className={classNames}>
      {label && <div className="form-item-header">
        <p>{label}</p>
        {tooltip && <div className="item-tooltip">
          <span className="trigger"><i className="fa fa-question-circle" /></span>
          <div className="content">{tooltip}</div>
        </div>}
      </div>}
      <div className="form-item-field">
        <Controller name={id as FieldPath<TFieldValues>}
                    control={control}
                    defaultValue={valuesDefault as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>}
                    render={({ field: { onChange, value, ref } }) =>
                      <Select ref={ref}
                              classNamePrefix="rs"
                              className="rs"
                              value={getCurrentValues(value)}
                              onChange={val => {
                                const values = val?.map(c => c.value);
                                onChangeCb(values, onChange);
                              }}
                              placeholder={placeholder}
                              options={options}
                              isMulti />
                    } />
      </div>
      {(error && error[id]) && <div className="form-item-error">{error[id].message}</div> }
    </label>
  );
};

FormMultiSelect.defaultProps = {
  expectedResult: 'array'
};
