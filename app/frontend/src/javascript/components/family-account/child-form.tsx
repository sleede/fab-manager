import React from 'react';
import { useForm } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import { Child } from '../../models/child';
import { TDateISODate } from '../../typings/date-iso';
import { FormInput } from '../form/form-input';

interface ChildFormProps {
  child: Child;
  onChange: (field: string, value: string | TDateISODate) => void;
}

/**
 * A form for creating or editing a child.
 */
export const ChildForm: React.FC<ChildFormProps> = ({ child, onChange }) => {
  const { t } = useTranslation('public');

  const { register, formState } = useForm<Child>({
    defaultValues: child
  });

  /**
   * Handle the change of a child form field
   */
  const handleChange = (event: React.ChangeEvent<HTMLInputElement>): void => {
    onChange(event.target.id, event.target.value);
  };

  return (
    <div className="child-form">
      <div className="info-area">
        {t('app.public.child_form.child_form_info')}
      </div>
      <form>
        <FormInput id="first_name"
          register={register}
          rules={{ required: true }}
          formState={formState}
          label={t('app.public.child_form.first_name')}
          onChange={handleChange}
        />
        <FormInput id="last_name"
          register={register}
          rules={{ required: true }}
          formState={formState}
          label={t('app.public.child_form.last_name')}
          onChange={handleChange}
        />
      </form>
    </div>
  );
};
