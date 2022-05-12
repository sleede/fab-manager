import React from 'react';
import { useTranslation } from 'react-i18next';
import PlanCategoryAPI from '../../api/plan-category';
import { PlanCategory } from '../../models/plan-category';
import { Loader } from '../base/loader';
import { useForm, SubmitHandler } from 'react-hook-form';
import { FormInput } from '../form/form-input';
import { FabAlert } from '../base/fab-alert';
import { FabButton } from '../base/fab-button';
import { FormRichText } from '../form/form-rich-text';

interface PlanCategoryFormProps {
  action: 'create' | 'update',
  category: PlanCategory,
  onSuccess: (message: string) => void,
  onError: (message: string) => void
}

const PlanCategoryFormComponent: React.FC<PlanCategoryFormProps> = ({ action, category, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const { register, control, handleSubmit } = useForm<PlanCategory>({ defaultValues: { ...category } });
  /**
   * The action has been confirmed by the user.
   * Push the created/updated plan-category to the API.
   */
  const onSubmit: SubmitHandler<PlanCategory> = (data: PlanCategory) => {
    switch (action) {
      case 'create':
        PlanCategoryAPI.create(data).then(() => {
          onSuccess(t('app.admin.manage_plan_category.create_category.success'));
        }).catch((error) => {
          onError(t('app.admin.manage_plan_category.create_category.error') + error);
        });
        break;
      case 'update':
        PlanCategoryAPI.update(data).then(() => {
          onSuccess(t('app.admin.manage_plan_category.update_category.success'));
        }).catch((error) => {
          onError(t('app.admin.manage_plan_category.update_category.error') + error);
        });
        break;
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <FormInput id='name' register={register} rules={{ required: 'true' }} label={t('app.admin.manage_plan_category.name')} />

      <FormRichText control={control} id="description" label={t('app.admin.manage_plan_category.description')} limit={100} />

      <FormInput id='weight' register={register} type='number' label={t('app.admin.manage_plan_category.significance')} />
      <FabAlert level="info" className="significance-info">
        {t('app.admin.manage_plan_category.info')}
      </FabAlert>
      <FabButton type='submit'>{t(`app.admin.manage_plan_category.${action}_category.cta`)}</FabButton>
    </form>
  );
};

export const PlanCategoryForm: React.FC<PlanCategoryFormProps> = ({ action, category, onSuccess, onError }) => {
  return (
    <Loader>
      <PlanCategoryFormComponent action={action} category={category} onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};
