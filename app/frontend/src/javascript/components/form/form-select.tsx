import { useState, useEffect } from 'react';
import Select from 'react-select';
import CreatableSelect from 'react-select/creatable';
import { Controller, Path } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FieldPathValue, UnpackNestedValue } from 'react-hook-form/dist/types';
import { FormControlledComponent } from '../../models/form-component';
import { AbstractFormItem, AbstractFormItemProps } from './abstract-form-item';
import { SelectOption } from '../../models/select';

type FormSelectProps<TFieldValues, TContext extends object, TOptionValue, TOptionLabel> = FormControlledComponent<TFieldValues, TContext> & AbstractFormItemProps<TFieldValues> & {
  options: Array<SelectOption<TOptionValue, TOptionLabel>>,
  valueDefault?: TOptionValue,
  onChange?: (value: TOptionValue) => void,
  placeholder?: string,
  clearable?: boolean,
  creatable?: boolean,
}

/**
 * This component is a wrapper for react-select to use with react-hook-form
 */
export const FormSelect = <TFieldValues extends FieldValues, TContext extends object, TOptionValue, TOptionLabel>({ id, label, tooltip, className, control, placeholder, options, valueDefault, error, warning, rules, disabled = false, onChange, clearable = false, formState, creatable = false }: FormSelectProps<TFieldValues, TContext, TOptionValue, TOptionLabel>) => {
  const [isDisabled, setIsDisabled] = useState<boolean>(false);

  useEffect(() => {
    if (typeof disabled === 'function') {
      setIsDisabled(disabled(id));
    } else {
      setIsDisabled(disabled);
    }
  }, [disabled]);

  /**
   * The following callback will trigger the onChange callback, if it was passed to this component,
   * when the selected option changes.
   */
  const onChangeCb = (newValue: TOptionValue): void => {
    if (typeof onChange === 'function') {
      onChange(newValue);
    }
  };

  // if the user can create new options, we need to use a different component
  const AbstractSelect = creatable ? CreatableSelect : Select;

  return (
    <AbstractFormItem id={id} label={label} tooltip={tooltip}
                      className={`form-select ${className || ''}`} formState={formState}
                      error={error} warning={warning} rules={rules}
                      disabled={disabled}>
      <Controller name={id as FieldPath<TFieldValues>}
                  control={control}
                  defaultValue={valueDefault as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>}
                  rules={rules}
                  render={({ field: { onChange, value, ref } }) =>
                    <AbstractSelect ref={ref}
                                    classNamePrefix="rs"
                                    className="rs"
                                    value={options.find(c => c.value === value)}
                                    onChange={val => {
                                      onChangeCb(val.value);
                                      onChange(val.value);
                                    }}
                                    placeholder={placeholder}
                                    isDisabled={isDisabled}
                                    isClearable={clearable}
                                    options={options}
                                    isOptionDisabled={(option) => option.disabled}/>
                  } />
    </AbstractFormItem>
  );
};
