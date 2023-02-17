import { useState, useEffect } from 'react';
import AsyncSelect from 'react-select/async';
import Select from 'react-select';
import AsyncCreatableSelect from 'react-select/async-creatable';
import CreatableSelect from 'react-select/creatable';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FormControlledComponent } from '../../models/form-component';
import { AbstractFormItem, AbstractFormItemProps } from './abstract-form-item';
import { useTranslation } from 'react-i18next';
import { Controller, FieldPathValue, Path } from 'react-hook-form';
import { UnpackNestedValue } from 'react-hook-form/dist/types/form';

type CommonProps<TFieldValues, TContext extends object, TOptionValue> = FormControlledComponent<TFieldValues, TContext> & AbstractFormItemProps<TFieldValues> & {
  valuesDefault?: Array<TOptionValue>,
  onChange?: (values: Array<TOptionValue>) => void,
  placeholder?: string,
  creatable?: boolean,
  selectKey?: string,
}

// we should provide either an array of options or a function that returns a promise, but not both
type OptionsProps<TOptionValue> =
  { options: Array<selectOption<TOptionValue>>, loadOptions?: never } |
  { options?: never, loadOptions: (inputValue: string, callback: (options: Array<selectOption<TOptionValue>>) => void) => void };

type FormSelectProps<TFieldValues, TContext extends object, TOptionValue> = CommonProps<TFieldValues, TContext, TOptionValue> & OptionsProps<TOptionValue>;

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption<TOptionValue> = { value: TOptionValue, label: string, select?: boolean };

/**
 * This component is a wrapper around react-select to use with react-hook-form.
 * It is a multi-select component.
 */
export const FormMultiSelect = <TFieldValues extends FieldValues, TContext extends object, TOptionValue>({ id, label, tooltip, className, control, placeholder, options, valuesDefault, error, rules, disabled, onChange, formState, warning, loadOptions, creatable, selectKey }: FormSelectProps<TFieldValues, TContext, TOptionValue>) => {
  const { t } = useTranslation('shared');

  const [isDisabled, setIsDisabled] = useState<boolean>(false);
  const [allOptions, setAllOptions] = useState<Array<selectOption<TOptionValue>>>(options || []);

  useEffect(() => {
    if (typeof disabled === 'function') {
      setIsDisabled(disabled(id));
    } else {
      setIsDisabled(disabled);
    }
  }, [disabled]);

  useEffect(() => {
    if (typeof loadOptions === 'function') {
      loadOptions('', options => {
        setTimeout(() => setAllOptions(options), 1);
      });
    }
  }, [loadOptions]);

  /**
   * The following callback will set the new selected options in the component state.
   */
  const onChangeCb = (newValues: Array<TOptionValue>, rhfOnChange: (values: Array<TOptionValue>) => void): void => {
    if (typeof onChange === 'function') {
      onChange(newValues);
    }
    if (typeof rhfOnChange === 'function') {
      rhfOnChange(newValues);
    }
  };

  /**
   * This function will return the currently selected options, according to the selectedOptions state.
   */
  const getCurrentValues = (value: Array<TOptionValue>): Array<selectOption<TOptionValue>> => {
    return allOptions?.filter(c => value?.includes(c.value));
  };

  /**
   * When the select is 'creatable', this callback handle the creation and the selection of a new option.
   */
  const handleCreate = (inputValue: string, currentSelection: Array<TOptionValue>, rhfOnChange: (values: Array<TOptionValue>) => void) => {
    // add the new value to the list of options
    const newValue = inputValue as unknown as TOptionValue;
    const newOption = { value: newValue, label: inputValue };
    setAllOptions([...allOptions, newOption]);
    if (typeof rhfOnChange === 'function') {
      rhfOnChange([...currentSelection, newValue]);
    }
  };

  /**
   * Translate the label for a new item when the select is "creatable"
   */
  const formatCreateLabel = (inputValue: string): string => {
    return t('app.shared.form_multi_select.create_label', { VALUE: inputValue });
  };

  // if the user can create new options, and/or load the options through a promise need to use different components
  const AbstractSelect = loadOptions
    ? creatable
      ? AsyncCreatableSelect
      : AsyncSelect
    : creatable
      ? CreatableSelect
      : Select;

  return (
    <AbstractFormItem id={id} formState={formState} label={label}
                      className={`form-multi-select ${className || ''}`} tooltip={tooltip}
                      disabled={disabled}
                      rules={rules} error={error} warning={warning}>
      <Controller name={id as FieldPath<TFieldValues>}
                  control={control}
                  defaultValue={valuesDefault as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>}
                  rules={rules}
                  render={({ field: { onChange: rhfOnChange, value, ref } }) => {
                    const selectProps = {
                      classNamePrefix: 'rs',
                      className: 'rs',
                      ref,
                      key: selectKey,
                      value: getCurrentValues(value),
                      placeholder,
                      isDisabled,
                      isMulti: true,
                      onChange: val => onChangeCb(val?.map(c => c.value), rhfOnChange),
                      options: allOptions
                    };

                    if (loadOptions) {
                      Object.assign(selectProps, { loadOptions, defaultOptions: true, cacheOptions: true });
                    }

                    if (creatable) {
                      Object.assign(selectProps, {
                        formatCreateLabel,
                        onCreateOption: inputValue => handleCreate(inputValue, value, rhfOnChange)
                      });
                    }

                    return (<AbstractSelect {...selectProps} />);
                  }}
      />
    </AbstractFormItem>
  );
};

FormMultiSelect.defaultProps = {
  creatable: false,
  disabled: false
};
