import React, { InputHTMLAttributes, ReactNode, useCallback, useEffect, useState } from 'react';
import { FieldPathValue } from 'react-hook-form';
import { debounce as _debounce, get as _get } from 'lodash';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FormComponent } from '../../models/form-component';

interface FormInputProps<TFieldValues> extends InputHTMLAttributes<HTMLInputElement>, FormComponent<TFieldValues>{
  id: string,
  label?: string,
  tooltip?: ReactNode,
  icon?: ReactNode,
  addOn?: ReactNode,
  addOnClassName?: string,
  debounce?: number,
}

/**
 * This component is a template for an input component to use within React Hook Form
 */
export const FormInput = <TFieldValues extends FieldValues>({ id, register, label, tooltip, defaultValue, icon, className, rules, readOnly, disabled, type, addOn, addOnClassName, placeholder, error, warning, formState, step, onChange, debounce }: FormInputProps<TFieldValues>) => {
  const [isDirty, setIsDirty] = useState(false);
  const [fieldError, setFieldError] = useState(error);

  useEffect(() => {
    setIsDirty(_get(formState?.dirtyFields, id));
    setFieldError(_get(formState?.errors, id));
  }, [formState]);

  useEffect(() => {
    setFieldError(error);
  }, [error]);

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
    'form-input form-item',
    `${className || ''}`,
    `${type === 'hidden' ? 'is-hidden' : ''}`,
    `${isDirty && fieldError ? 'is-incorrect' : ''}`,
    `${isDirty && warning ? 'is-warned' : ''}`,
    `${rules && rules.required ? 'is-required' : ''}`,
    `${readOnly ? 'is-readonly' : ''}`,
    `${disabled ? 'is-disabled' : ''}`
  ].join(' ');

  return (
    <label className={classNames}>
      {label && <div className='form-item-header'>
        <p>{label}</p>
        {tooltip && <div className="item-tooltip">
          <span className="trigger"><i className="fa fa-question-circle" /></span>
          <div className="content">{tooltip}</div>
        </div>}
      </div>}
      <div className='form-item-field'>
        {icon && <span className="icon">{icon}</span>}
        <input id={id}
          {...register(id as FieldPath<TFieldValues>, {
            ...rules,
            valueAsNumber: type === 'number',
            value: defaultValue as FieldPathValue<TFieldValues, FieldPath<TFieldValues>>,
            onChange: (e) => { handleChange(e); }
          })}
          type={type}
          step={step}
          disabled={disabled}
          readOnly={readOnly}
          placeholder={placeholder} />
        {addOn && <span className={`addon ${addOnClassName || ''}`}>{addOn}</span>}
      </div>
      {(isDirty && fieldError) && <div className="form-item-error">{fieldError.message}</div> }
      {(isDirty && warning) && <div className="form-item-warning">{warning.message}</div> }
    </label>
  );
};
