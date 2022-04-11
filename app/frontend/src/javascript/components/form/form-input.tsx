import React, { InputHTMLAttributes, ReactNode } from 'react';
import { FieldPathValue } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FormComponent } from '../../models/form-component';

interface FormInputProps<TFieldValues> extends InputHTMLAttributes<HTMLInputElement>, FormComponent<TFieldValues>{
  id: string,
  label?: string,
  tooltip?: string,
  icon?: ReactNode,
  addOn?: ReactNode,
  addOnClassName?: string,
}

/**
 * This component is a template for an input component to use within React Hook Form
 */
export const FormInput = <TFieldValues extends FieldValues>({ id, register, label, tooltip, defaultValue, icon, className, rules, readOnly, disabled, type, addOn, addOnClassName, placeholder, error, step }: FormInputProps<TFieldValues>) => {
  // Compose classnames from props
  const classNames = `
    form-input form-item ${className || ''}
    ${type === 'hidden' ? 'is-hidden' : ''}
    ${error && error[id] ? 'is-incorrect' : ''}
    ${rules && rules.required ? 'is-required' : ''}
    ${readOnly ? 'is-readOnly' : ''}
    ${disabled ? 'is-disabled' : ''}`;

  return (
    <label className={classNames}>
      {label && <div className='form-item-header'>
        <p>{label}</p>
        {/* TODO: Create tooltip component */}
        {tooltip && <span>{tooltip}</span>}
      </div>}
      <div className='form-item-field'>
        {icon && <span className="icon">{icon}</span>}
        <input id={id}
          {...register(id as FieldPath<TFieldValues>, {
            ...rules,
            valueAsNumber: type === 'number',
            value: defaultValue as FieldPathValue<TFieldValues, FieldPath<TFieldValues>>
          })}
          type={type}
          step={step}
          disabled={disabled}
          readOnly={readOnly}
          placeholder={placeholder} />
        {addOn && <span className={`addon ${addOnClassName || ''}`}>{addOn}</span>}
      </div>
      {(error && error[id]) && <div className="form-item-error">{error[id].message}</div> }
    </label>
  );
};
