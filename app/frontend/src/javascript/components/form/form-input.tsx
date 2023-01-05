import { ReactNode, useCallback } from 'react';
import * as React from 'react';
import { FieldPathValue } from 'react-hook-form';
import { debounce as _debounce } from 'lodash';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FormComponent } from '../../models/form-component';
import { AbstractFormItem, AbstractFormItemProps } from './abstract-form-item';

interface FormInputProps<TFieldValues, TInputType> extends FormComponent<TFieldValues>, AbstractFormItemProps<TFieldValues> {
  icon?: ReactNode,
  addOn?: ReactNode,
  addOnAction?: (event: React.MouseEvent<HTMLButtonElement>) => void,
  addOnClassName?: string,
  addOnAriaLabel?: string,
  debounce?: number,
  type?: 'text' | 'date' | 'password' | 'url' | 'time' | 'tel' | 'search' | 'number' | 'month' | 'email' | 'datetime-local' | 'week' | 'hidden' | 'file',
  accept?: string,
  defaultValue?: TInputType,
  placeholder?: string,
  step?: number | 'any',
  onChange?: (event: React.ChangeEvent<HTMLInputElement>) => void,
  nullable?: boolean,
  ariaLabel?: string,
}

/**
 * This component is a template for an input component to use within React Hook Form
 */
export const FormInput = <TFieldValues extends FieldValues, TInputType>({ id, register, label, tooltip, defaultValue, icon, className, rules, disabled, type, addOn, addOnAction, addOnClassName, addOnAriaLabel, placeholder, error, warning, formState, step, onChange, debounce, accept, nullable = false, ariaLabel }: FormInputProps<TFieldValues, TInputType>) => {
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
    `${className || ''}`,
    `${type === 'hidden' ? 'is-hidden' : ''}`
  ].join(' ');

  return (
    <AbstractFormItem id={id} formState={formState} label={label}
                      className={`form-input ${classNames}`} tooltip={tooltip}
                      disabled={disabled}
                      rules={rules} error={error} warning={warning}>
        {icon && <span className="icon">{icon}</span>}
        <input id={id} aria-label={ariaLabel}
          {...register(id as FieldPath<TFieldValues>, {
            ...rules,
            valueAsDate: type === 'date',
            setValueAs: v => ([null, ''].includes(v) && nullable) ? null : (type === 'number' ? parseFloat(v) : v),
            value: defaultValue as FieldPathValue<TFieldValues, FieldPath<TFieldValues>>,
            onChange: (e) => { handleChange(e); }
          })}
          type={type}
          step={step}
          disabled={typeof disabled === 'function' ? disabled(id) : disabled}
          placeholder={placeholder}
          accept={accept} />
        {(type === 'file' && placeholder) && <span className='fab-button is-black file-placeholder'>{placeholder}</span>}
        {addOn && addOnAction && <button aria-label={addOnAriaLabel} type="button" onClick={addOnAction} className={`addon ${addOnClassName || ''} is-btn`}>{addOn}</button>}
        {addOn && !addOnAction && <span aria-label={addOnAriaLabel} className={`addon ${addOnClassName || ''}`}>{addOn}</span>}
    </AbstractFormItem>
  );
};
