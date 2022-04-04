import React, { ReactNode } from 'react';
import { FieldErrors, FieldPathValue, UseFormRegister, Validate } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';

type inputType = string|number|readonly string [];
type ruleTypes<TFieldValues> = {
  required?: boolean | string,
  pattern?: RegExp | {value: RegExp, message: string},
  minLength?: number,
  maxLength?: number,
  min?: number,
  max?: number,
  validate?: Validate<TFieldValues>;
};

interface RHFInputProps<TFieldValues> {
  id: string,
  register: UseFormRegister<TFieldValues>,
  label?: string,
  tooltip?: string,
  defaultValue?: inputType,
  icon?: ReactNode,
  addOn?: ReactNode,
  addOnClassName?: string,
  classes?: string,
  rules?: ruleTypes<TFieldValues>,
  readOnly?: boolean,
  disabled?: boolean,
  placeholder?: string,
  error?: FieldErrors,
  type?: 'text' | 'date' | 'password' | 'url' | 'time' | 'tel' | 'search' | 'number' | 'month' | 'email' | 'datetime-local' | 'week',
  step?: number | 'any'
}

/**
 * This component is a template for an input component to use within React Hook Form
 */
export const RHFInput = <TFieldValues extends FieldValues>({ id, register, label, tooltip, defaultValue, icon, classes, rules, readOnly, disabled, type, addOn, addOnClassName, placeholder, error, step }: RHFInputProps<TFieldValues>) => {
  // Compose classnames from props
  const classNames = `
    rhf-input ${classes || ''}
    ${error && error[id] ? 'is-incorrect' : ''}
    ${rules && rules.required ? 'is-required' : ''}
    ${readOnly ? 'is-readOnly' : ''}
    ${disabled ? 'is-disabled' : ''}`;

  return (
    <label className={classNames}>
      {label && <div className='rhf-input-header'>
        <p>{label}</p>
        {/* TODO: Create tooltip component */}
        {tooltip && <span>{tooltip}</span>}
      </div>}
      <div className='rhf-input-field'>
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
      {(error && error[id]) && <div className="rhf-input-error">{error[id].message}</div> }
    </label>
  );
};
