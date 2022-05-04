import React, { useEffect } from 'react';
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
export const FormMultiSelect = <TFieldValues extends FieldValues, TContext extends object, TOptionValue>({ id, label, tooltip, className, control, placeholder, options, valuesDefault, error, rules, disabled, onChange, formState, readOnly, warning, expectedResult }: FormSelectProps<TFieldValues, TContext, TOptionValue>) => {
  const [isDisabled, setIsDisabled] = React.useState<boolean>(false);

  useEffect(() => {
    if (typeof disabled === 'function') {
      setIsDisabled(disabled(id) || readOnly);
    } else {
      setIsDisabled(disabled || readOnly);
    }
  }, [disabled]);

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
    <AbstractFormItem id={id} formState={formState} label={label}
                      className={`form-multi-select ${className || ''}`} tooltip={tooltip}
                      disabled={disabled} readOnly={readOnly}
                      rules={rules} error={error} warning={warning}>
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
                              isDisabled={isDisabled}
                              isMulti />
                    } />
    </AbstractFormItem>
  );
};

FormMultiSelect.defaultProps = {
  expectedResult: 'array'
};
