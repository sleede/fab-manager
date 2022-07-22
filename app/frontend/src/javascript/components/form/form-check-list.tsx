import React, { BaseSyntheticEvent } from 'react';
import { Controller, Path, FieldPathValue } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { useTranslation } from 'react-i18next';
import { UnpackNestedValue } from 'react-hook-form/dist/types';
import { FormControlledComponent } from '../../models/form-component';
import { AbstractFormItem, AbstractFormItemProps } from './abstract-form-item';
import { FabButton } from '../base/fab-button';

/**
 * Checklist Option format
 */
export type ChecklistOption<TOptionValue> = { value: TOptionValue, label: string };

interface FormCheckListProps<TFieldValues, TOptionValue, TContext extends object> extends FormControlledComponent<TFieldValues, TContext>, AbstractFormItemProps<TFieldValues> {
  defaultValue?: Array<TOptionValue>,
  options: Array<ChecklistOption<TOptionValue>>,
  onChange?: (values: Array<TOptionValue>) => void,
}

/**
 * This component is a template for an check list component to use within React Hook Form
 */
export const FormCheckList = <TFieldValues extends FieldValues, TOptionValue, TContext extends object>({ id, control, label, tooltip, defaultValue, className, rules, disabled, error, warning, formState, onChange, options }: FormCheckListProps<TFieldValues, TOptionValue, TContext>) => {
  const { t } = useTranslation('shared');

  /**
   * Verify if the provided option is currently ticked
   */
  const isChecked = (values: Array<TOptionValue>, option: ChecklistOption<TOptionValue>): boolean => {
    return !!values?.includes(option.value);
  };

  /**
   * Callback triggered when a checkbox is ticked or unticked.
   */
  const toggleCheckbox = (option: ChecklistOption<TOptionValue>, values: Array<TOptionValue> = [], cb: (value: Array<TOptionValue>) => void) => {
    return (event: BaseSyntheticEvent) => {
      let newValues: Array<TOptionValue> = [];
      if (event.target.checked) {
        newValues = values.concat(option.value);
      } else {
        newValues = values.filter(v => v !== option.value);
      }
      cb(newValues);
      if (typeof onChange === 'function') {
        onChange(newValues);
      }
    };
  };

  /**
   * Callback triggered to select all options
   */
  const allSelect = (cb: (value: Array<TOptionValue>) => void) => {
    return () => {
      const newValues: Array<TOptionValue> = options.map(o => o.value);
      cb(newValues);
      if (typeof onChange === 'function') {
        onChange(newValues);
      }
    };
  };

  // Compose classnames from props
  const classNames = [
    `${className || ''}`
  ].join(' ');

  return (
    <AbstractFormItem id={id} formState={formState} label={label}
                      className={`form-check-list form-input ${classNames}`} tooltip={tooltip}
                      disabled={disabled}
                      rules={rules} error={error} warning={warning}>
        <Controller name={id as FieldPath<TFieldValues>}
                    control={control}
                    defaultValue={defaultValue as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>}
                    rules={rules}
                    render={({ field: { onChange, value } }) => {
                      return (
                        <>
                          <div className="checklist">
                            {options.map((option, k) => {
                              return (
                                <div key={k} className="checklist-item">
                                  <input id={`option-${k}`} type="checkbox" checked={isChecked(value, option)} onChange={toggleCheckbox(option, value, onChange)} />
                                  <label htmlFor={`option-${k}`}>{option.label}</label>
                                </div>
                              );
                            })}
                          </div>
                          <FabButton type="button" onClick={allSelect(onChange)} className="checklist-all-button">{t('app.shared.form_check_list.select_all')}</FabButton>
                        </>
                      );
                    }} />
    </AbstractFormItem>
  );
};
