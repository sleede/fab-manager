import React from 'react';
import { useForm } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import moment from 'moment';
import { Child } from '../../models/child';
import { TDateISODate } from '../../typings/date-iso';
import { FormInput } from '../form/form-input';
import { FabButton } from '../base/fab-button';

interface ChildFormProps {
  child: Child;
  onChange: (field: string, value: string | TDateISODate) => void;
  onSubmit: (data: Child) => void;
}

/**
 * A form for creating or editing a child.
 */
export const ChildForm: React.FC<ChildFormProps> = ({ child, onChange, onSubmit }) => {
  const { t } = useTranslation('public');

  const { register, formState, handleSubmit } = useForm<Child>({
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
      <form onSubmit={handleSubmit(onSubmit)}>
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
        <FormInput id="birthday"
          register={register}
          rules={{ required: true, validate: (value) => moment(value).isBefore(moment().subtract(18, 'year')) }}
          formState={formState}
          label={t('app.public.child_form.birthday')}
          type="date"
          max={moment().subtract(18, 'year').format('YYYY-MM-DD')}
          onChange={handleChange}
        />
        <FormInput id="phone"
          register={register}
          formState={formState}
          label={t('app.public.child_form.phone')}
          onChange={handleChange}
          type="tel"
        />
        <FormInput id="email"
          register={register}
          rules={{ required: true }}
          formState={formState}
          label={t('app.public.child_form.email')}
          onChange={handleChange}
        />

        <div className="actions">
          <FabButton type="button" onClick={handleSubmit(onSubmit)}>
            {t('app.public.child_form.save')}
          </FabButton>
        </div>
      </form>
    </div>
  );
};
