import React, { ReactNode, useCallback } from 'react';
import { FieldPathValue } from 'react-hook-form';
import { debounce as _debounce } from 'lodash';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FormComponent } from '../../models/form-component';
import { AbstractFormItem, AbstractFormItemProps } from './abstract-form-item';

interface FormInputProps<TFieldValues, TInputType> extends FormComponent<TFieldValues>, AbstractFormItemProps<TFieldValues> {
  icon?: ReactNode,
  addOn?: ReactNode,
  addOnClassName?: string,
  debounce?: number,
  type?: 'text' | 'date' | 'password' | 'url' | 'time' | 'tel' | 'search' | 'number' | 'month' | 'email' | 'datetime-local' | 'week' | 'hidden' | 'file',
  accept?: string,
  defaultValue?: TInputType,
  placeholder?: string,
  step?: number | 'any',
  onChange?: (event: React.ChangeEvent<HTMLInputElement>) => void,
}

/**
 * This component is a template for an input component to use within React Hook Form
 */
export const FormInput = <TFieldValues extends FieldValues, TInputType>({ id, register, label, tooltip, defaultValue, icon, className, rules, readOnly, disabled, type, addOn, addOnClassName, placeholder, error, warning, formState, step, onChange, debounce, accept }: FormInputProps<TFieldValues, TInputType>) => {
  /**
   * Debounced (ie. temporised) version of the 'on change' callback.
   */
  const debouncedOnChange = debounce ? useCallback(_debounce(onChange, debounce), [debounce]) : null;

  /**
   * Handle the change of content in the input field, and trigger the parent callback, if any
   */
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (typeof onChange === 'function') {
      if (debouncedOnChange) {
        debouncedOnChange(e);
      } else {
        onChange(e);
      }
    }
  };

  // Compose classnames from props
  const classNames = [
    'form-input',
    `${className || ''}`,
    `${type === 'hidden' ? 'is-hidden' : ''}`
  ].join(' ');

  return (
    <AbstractFormItem id={id} formState={formState} label={label}
                      className={classNames} tooltip={tooltip}
                      disabled={disabled} readOnly={readOnly}
                      rules={rules} error={error} warning={warning}>
        {icon && <span className="icon">{icon}</span>}
        <input id={id}
          {...register(id as FieldPath<TFieldValues>, {
            ...rules,
            valueAsNumber: type === 'number',
            valueAsDate: type === 'date',
            value: defaultValue as FieldPathValue<TFieldValues, FieldPath<TFieldValues>>,
            onChange: (e) => { handleChange(e); }
          })}
          type={type}
          step={step}
          disabled={typeof disabled === 'function' ? disabled(id) : disabled}
          readOnly={readOnly}
          placeholder={placeholder}
          accept={accept} />
        {addOn && <span className={`addon ${addOnClassName || ''}`}>{addOn}</span>}
    </AbstractFormItem>
  );
};
