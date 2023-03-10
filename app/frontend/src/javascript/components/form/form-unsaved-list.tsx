import { FieldArrayWithId } from 'react-hook-form/dist/types/fieldArray';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import React, { ReactNode } from 'react';
import { X } from 'phosphor-react';
import { FormInput } from './form-input';
import { FieldArrayPath } from 'react-hook-form/dist/types/path';

interface FormUnsavedListProps<TFieldValues, TFieldArrayName extends FieldArrayPath<TFieldValues>, TKeyName extends string> {
  fields: Array<FieldArrayWithId<TFieldValues, TFieldArrayName, TKeyName>>,
  onRemove?: (index: number) => void,
  register: UseFormRegister<TFieldValues>,
  className?: string,
  title: string,
  shouldRenderField?: (field: FieldArrayWithId<TFieldValues, TFieldArrayName, TKeyName>) => boolean,
  renderField: (field: FieldArrayWithId<TFieldValues, TFieldArrayName, TKeyName>) => ReactNode,
  formAttributeName: `${string}_attributes`,
  formAttributes: Array<keyof FieldArrayWithId<TFieldValues, TFieldArrayName>>,
  saveReminderLabel?: string | ReactNode,
  cancelLabel?: string | ReactNode
}

/**
 * This component render a list of unsaved attributes, created elsewhere than in the form (e.g. in a modal dialog)
 * and pending for the form to be saved.
 */
export const FormUnsavedList = <TFieldValues extends FieldValues = FieldValues, TFieldArrayName extends FieldArrayPath<TFieldValues> = FieldArrayPath<TFieldValues>, TKeyName extends string = 'id'>({ fields, onRemove, register, className, title, shouldRenderField = () => true, renderField, formAttributeName, formAttributes, saveReminderLabel, cancelLabel }: FormUnsavedListProps<TFieldValues, TFieldArrayName, TKeyName>) => {
  const { t } = useTranslation('shared');

  /**
   * Render an unsaved field
   */
  const renderUnsavedField = (field: FieldArrayWithId<TFieldValues, TFieldArrayName, TKeyName>, index: number): ReactNode => {
    return (
      <div key={index} className="unsaved-field">
        {renderField(field)}
        <p className="cancel-action" onClick={() => onRemove(index)}>
          {cancelLabel || t('app.shared.form_unsaved_list.cancel')}
          <X size={20} />
        </p>
        {formAttributes.map((attribute, attrIndex) => (
          <FormInput key={attrIndex} id={`${formAttributeName}.${index}.${attribute}`} register={register} type="hidden" />
        ))}
      </div>
    );
  };

  if (fields.filter(shouldRenderField).length === 0) return null;

  return (
    <div className={`form-unsaved-list ${className || ''}`}>
      <span className="title">{title}</span>
      <span className="save-notice">{saveReminderLabel || t('app.shared.form_unsaved_list.save_reminder')}</span>
      {fields.map((field, index) => {
        if (!shouldRenderField(field)) return false;
        return renderUnsavedField(field, index);
      }).filter(Boolean)}
    </div>
  );
};
