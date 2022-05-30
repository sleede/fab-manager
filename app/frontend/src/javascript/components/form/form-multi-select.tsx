import React, { useEffect } from 'react';
import Select from 'react-select';
import { difference } from 'lodash';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FormComponent } from '../../models/form-component';
import { AbstractFormItem, AbstractFormItemProps } from './abstract-form-item';
import CreatableSelect from 'react-select/creatable';
import { useTranslation } from 'react-i18next';
import { FieldPathValue, Path } from 'react-hook-form';
import { UnpackNestedValue, UseFormSetValue } from 'react-hook-form/dist/types/form';

interface CommonProps<TFieldValues, TOptionValue> extends FormComponent<TFieldValues>, AbstractFormItemProps<TFieldValues> {
  options: Array<selectOption<TOptionValue>>,
  valuesDefault?: Array<TOptionValue>,
  onChange?: (values: Array<TOptionValue>) => void,
  placeholder?: string,
  formatResult?: (values: Array<TOptionValue>) => string,
}

// if creatable is set to true, the setValue must be provided
type CreatableProps<TFieldValues, TOptionValue> =
  { creatable: true, setValue: UseFormSetValue<TFieldValues>, currentValue?: Array<TOptionValue> } |
  { creatable?: false, setValue?: never, currentValue?: never };

type FormSelectProps<TFieldValues, TOptionValue> = CommonProps<TFieldValues, TOptionValue> & CreatableProps<TFieldValues, TOptionValue>;

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption<TOptionValue> = { value: TOptionValue, label: string };

/**
 * This component is a wrapper around react-select to use with react-hook-form.
 * It is a multi-select component.
 */
export const FormMultiSelect = <TFieldValues extends FieldValues, TOptionValue>({ id, label, tooltip, className, register, placeholder, options, valuesDefault, error, rules, disabled, onChange, formState, warning, formatResult, creatable, setValue, currentValue }: FormSelectProps<TFieldValues, TOptionValue>) => {
  const { t } = useTranslation('shared');

  const [isDisabled, setIsDisabled] = React.useState<boolean>(false);
  const [allOptions, setAllOptions] = React.useState<Array<selectOption<TOptionValue>>>(options);
  const [createdOptions, setCreatedOptions] = React.useState<Array<selectOption<TOptionValue>>>([]);
  const [selectedOptions, setSelectedOptions] = React.useState<Array<TOptionValue>>(valuesDefault);

  useEffect(() => {
    if (typeof disabled === 'function') {
      setIsDisabled(disabled(id));
    } else {
      setIsDisabled(disabled);
    }
  }, [disabled]);

  useEffect(() => {
    setAllOptions(options.concat(createdOptions));
  }, [options, createdOptions]);

  useEffect(() => {
    if (typeof onChange === 'function') {
      onChange(selectedOptions);
    }
    setValue(
      id as Path<TFieldValues>,
      getResult() as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
    );
  }, [selectedOptions]);

  useEffect(() => {
    if (selectedOptions === undefined && currentValue && currentValue[0]) {
      setSelectedOptions(currentValue);
      const custom = difference(currentValue, allOptions.map(o => o.value));
      if (custom.length > 0) {
        setCreatedOptions(custom.map(c => {
          return { value: c, label: c as unknown as string };
        }));
      }
    }
  }, [currentValue]);

  /**
   * The following callback will set the new selected options in the component state.
   */
  const onChangeCb = (newValues: Array<TOptionValue>): void => {
    setSelectedOptions(newValues);
  };

  /**
   * This function will return the currently selected options, according to the selectedOptions state.
   */
  const getCurrentValues = (): Array<selectOption<TOptionValue>> => {
    return allOptions.filter(c => selectedOptions?.includes(c.value));
  };

  /**
   * Return the expected result (a string or an array).
   * This is used in the hidden input.
   */
  const getResult = (): string => {
    if (!selectedOptions) return undefined;

    if (typeof formatResult === 'function') {
      return formatResult(selectedOptions);
    } else {
      return selectedOptions.join(',');
    }
  };

  /**
   * When the select is 'creatable', this callback handle the creation and the selection of a new option.
   */
  const handleCreate = (inputValue: string) => {
    // add the new value to the list of options
    const newValue = inputValue as unknown as TOptionValue;
    const newOption = { value: newValue, label: inputValue };
    setCreatedOptions([...createdOptions, newOption]);

    // select the new option
    setSelectedOptions([...selectedOptions, newValue]);
  };

  /**
   * Translate the label for a new item when the select is "creatable"
   */
  const formatCreateLabel = (inputValue: string): string => {
    return t('app.shared.form_multi_select.create_label', { VALUE: inputValue });
  };

  // if the user can create new options, we need to use a different component
  const AbstractSelect = creatable ? CreatableSelect : Select;

  return (
    <AbstractFormItem id={id} formState={formState} label={label}
                      className={`form-multi-select ${className || ''}`} tooltip={tooltip}
                      disabled={disabled}
                      rules={rules} error={error} warning={warning}>
    <AbstractSelect classNamePrefix="rs"
                    className="rs"
                    value={getCurrentValues()}
                    onChange={val => {
                      const values = val?.map(c => c.value);
                      onChangeCb(values);
                    }}
                    onCreateOption={handleCreate}
                    formatCreateLabel={formatCreateLabel}
                    placeholder={placeholder}
                    options={allOptions}
                    isDisabled={isDisabled}
                    isMulti />
      <input id={id}
             type="hidden"
             {...register(id as FieldPath<TFieldValues>, {
               ...rules,
               value: getResult() as FieldPathValue<TFieldValues, FieldPath<TFieldValues>>
             })} />
    </AbstractFormItem>
  );
};

FormMultiSelect.defaultProps = {
  creatable: false,
  disabled: false
};
