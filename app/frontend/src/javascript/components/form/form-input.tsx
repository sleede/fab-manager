import { ReactNode, useCallback, useState, useEffect } from 'react';
import * as React from 'react';
import { FieldPathValue, UseFormGetValues } from 'react-hook-form';
import { debounce as _debounce } from 'lodash';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { Path, FieldPath } from 'react-hook-form/dist/types/path';
import { FormComponent } from '../../models/form-component';
import { AbstractFormItem, AbstractFormItemProps } from './abstract-form-item';

type FormInputProps<TFieldValues, TInputType> = FormComponent<TFieldValues> & AbstractFormItemProps<TFieldValues> & {
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
  maxLength?: number,
  getValues?: UseFormGetValues<TFieldValues>
}

/**
 * This component is a template for an input component to use within React Hook Form
 */
export const FormInput = <TFieldValues extends FieldValues, TInputType>({ id, register, getValues, label, tooltip, defaultValue, icon, className, rules, disabled, type, addOn, addOnAction, addOnClassName, addOnAriaLabel, placeholder, error, warning, formState, step, onChange, debounce, accept, nullable = false, ariaLabel, maxLength }: FormInputProps<TFieldValues, TInputType>) => {
  const [characterCount, setCharacterCount] = useState<number>(0);

  /**
   * Debounced (ie. temporised) version of the 'on change' callback.
   */
  const debouncedOnChange = debounce ? useCallback(_debounce(onChange, debounce), [debounce]) : null;

  /**
   * Handle the change of content in the input field, and trigger the parent callback, if any
   */
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setCharacterCount(e.currentTarget.value.length);
    if (typeof onChange === 'function') {
      if (debouncedOnChange) {
        debouncedOnChange(e);
      } else {
        onChange(e);
      }
    }
  };

  /**
   * Parse the inputted value before saving it in the RHF state
   */
  const parseValue = (value: string) => {
    if ([null, ''].includes(value) && nullable) {
      return null;
    } else {
      if (type === 'number') {
        const num: number = parseFloat(value);
        if (Number.isNaN(num) && nullable) {
          return null;
        }
        return num;
      }
      setCharacterCount(value.length);
      return value;
    }
  };

  // If maxLength and getValues is provided, uses input ref to initiate the countdown of characters
  useEffect(() => {
    if (getValues && maxLength) {
      setCharacterCount(getValues(id as Path<TFieldValues>).length);
    }
  }, [maxLength, getValues]);

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
            setValueAs: parseValue,
            value: defaultValue as FieldPathValue<TFieldValues, FieldPath<TFieldValues>>,
            onChange: (e) => { handleChange(e); }
          })}
          type={type}
          step={step}
          disabled={typeof disabled === 'function' ? disabled(id) : disabled}
          placeholder={placeholder}
          accept={accept}
          maxLength={maxLength} />
        {(type === 'file' && placeholder) && <span className='fab-button is-black file-placeholder'>{placeholder}</span>}
        {maxLength && <span className='countdown'>{characterCount} / {maxLength}</span>}
        {addOn && addOnAction && <button aria-label={addOnAriaLabel} type="button" onClick={addOnAction} className={`addon ${addOnClassName || ''} is-btn`}>{addOn}</button>}
        {addOn && !addOnAction && <span aria-label={addOnAriaLabel} className={`addon ${addOnClassName || ''}`}>{addOn}</span>}
    </AbstractFormItem>
  );
};
