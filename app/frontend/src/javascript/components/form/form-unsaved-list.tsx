import { FieldArrayWithId, UseFieldArrayRemove } from 'react-hook-form/dist/types/fieldArray';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import { ReactNode } from 'react';
import { X } from 'phosphor-react';
import { FormInput } from './form-input';
import { FieldArrayPath } from 'react-hook-form/dist/types/path';

interface FormUnsavedListProps<TFieldValues, TFieldArrayName extends FieldArrayPath<TFieldValues>, TKeyName extends string> {
  fields: Array<FieldArrayWithId<TFieldValues, TFieldArrayName, TKeyName>>,
  remove: UseFieldArrayRemove,
  register: UseFormRegister<TFieldValues>,
  className?: string,
  title: string,
  shouldRenderField?: (field: FieldArrayWithId<TFieldValues, TFieldArrayName, TKeyName>) => boolean,
  formAttributeName: string,
  renderFieldAttribute: (field: FieldArrayWithId<TFieldValues, TFieldArrayName, TKeyName>, attribute: string) => ReactNode,
}

/**
 * This component render a list of unsaved attributes, created elsewhere than in the form (e.g. in a modal dialog)
 * and pending for the form to be saved.
 */
export const FormUnsavedList = <TFieldValues extends FieldValues = FieldValues, TFieldArrayName extends FieldArrayPath<TFieldValues> = FieldArrayPath<TFieldValues>, TKeyName extends string = 'id'>({ fields, remove, register, className, title, shouldRenderField, formAttributeName, renderFieldAttribute }: FormUnsavedListProps<TFieldValues, TFieldArrayName, TKeyName>) => {
  const { t } = useTranslation('shared');

  /**
   * Render an unsaved field
   */
  const renderUnsavedField = (field: FieldArrayWithId<TFieldValues, TFieldArrayName, TKeyName>, index: number): ReactNode => {
    return (
      <div key={index} className="unsaved-field">
        {Object.keys(field).map(attribute => (
          <div className="grp" key={index}>
            {renderFieldAttribute(field, attribute)}
            <FormInput id={`${formAttributeName}.${index}.${attribute}`} register={register} type="hidden" />
          </div>
        ))}
        <p className="cancel-action" onClick={() => remove(index)}>
          {t('app.shared.form_unsaved_list.cancel')}
          <X size={20} />
        </p>
      </div>
    );
  };
  return (
    <div className={`form-unsaved-list ${className || ''}`}>
      <span className="title">{title}</span>
      <span className="save-notice">{t('app.shared.form_unsaved_list.save_reminder')}</span>
      {fields.map((field, index) => {
        if (typeof shouldRenderField === 'function' && !shouldRenderField(field)) return false;
        return renderUnsavedField(field, index);
      }).filter(Boolean)}
    </div>
  );
};
