import React from 'react';
import { FormControlledComponent } from '../../models/form-component';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FieldPathValue, UnpackNestedValue } from 'react-hook-form/dist/types';
import { Controller, Path } from 'react-hook-form';
import Switch from 'react-switch';
import { AbstractFormItem, AbstractFormItemProps } from './abstract-form-item';

interface FormSwitchProps<TFieldValues, TContext extends object> extends FormControlledComponent<TFieldValues, TContext>, AbstractFormItemProps<TFieldValues> {
  defaultValue?: boolean,
  onChange?: (value: boolean) => void,
}

/**
 * This component is a wrapper for react-switch, to use with react-hook-form.
 */
export const FormSwitch = <TFieldValues, TContext extends object>({ id, label, tooltip, className, error, rules, disabled, control, defaultValue, formState, readOnly, warning, onChange }: FormSwitchProps<TFieldValues, TContext>) => {
  /**
   * The following callback will trigger the onChange callback, if it was passed to this component,
   * when the selected option changes.
   */
  const onChangeCb = (newValue: boolean): void => {
    if (typeof onChange === 'function') {
      onChange(newValue);
    }
  };

  return (
    <AbstractFormItem id={id} formState={formState} label={label}
                      className={`form-switch ${className || ''}`} tooltip={tooltip}
                      disabled={disabled} readOnly={readOnly}
                      rules={rules} error={error} warning={warning}>
        <Controller name={id as FieldPath<TFieldValues>}
                    control={control}
                    defaultValue={defaultValue as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>}
                    rules={rules}
                    render={({ field: { onChange, value, ref } }) =>
                      <Switch onChange={val => {
                        onChange(val);
                        onChangeCb(val);
                      }}
                      checked={value as boolean || false}
                      height={19}
                      width={40}
                      ref={ref}
                      disabled={typeof disabled === 'function' ? disabled(id) : disabled}
                      readOnly={readOnly} />
                    } />
    </AbstractFormItem>
  );
};
