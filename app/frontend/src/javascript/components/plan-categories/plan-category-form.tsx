import * as React from 'react';
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

/**
 * Form to create/edit a plan category
 */
const PlanCategoryForm: React.FC<PlanCategoryFormProps> = ({ action, category, onSuccess, onError }) => {
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
          onSuccess(t('app.admin.plan_category_form.create.success'));
        }).catch((error) => {
          onError(t('app.admin.plan_category_form.create.error') + error);
        });
        break;
      case 'update':
        PlanCategoryAPI.update(data).then(() => {
          onSuccess(t('app.admin.plan_category_form.update.success'));
        }).catch((error) => {
          onError(t('app.admin.plan_category_form.update.error') + error);
        });
        break;
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <FormInput id='name' register={register} rules={{ required: 'true' }} label={t('app.admin.plan_category_form.name')} />

      <FormRichText control={control} id="description" label={t('app.admin.plan_category_form.description')} limit={100} />

      <FormInput id='weight' register={register} type='number' label={t('app.admin.plan_category_form.significance')} />
      <FabAlert level="info" className="significance-info">
        {t('app.admin.plan_category_form.info')}
      </FabAlert>
      <FabButton type='submit'>{t(`app.admin.plan_category_form.${action}.cta`)}</FabButton>
    </form>
  );
};

const PlanCategoryFormWrapper: React.FC<PlanCategoryFormProps> = (props) => {
  return (
    <Loader>
      <PlanCategoryForm {...props} />
    </Loader>
  );
};

export { PlanCategoryFormWrapper as PlanCategoryForm };
