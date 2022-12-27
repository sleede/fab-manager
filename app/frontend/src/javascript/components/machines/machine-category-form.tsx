import React from 'react';
import { useTranslation } from 'react-i18next';
import { SubmitHandler, useForm } from 'react-hook-form';
import { FormInput } from '../form/form-input';
import { FormChecklist } from '../form/form-checklist';
import { MachineCategory } from '../../models/machine-category';
import { FabButton } from '../base/fab-button';
import { Machine } from '../../models/machine';
import { SelectOption } from '../../models/select';

interface MachineCategoryFormProps {
  machines: Array<Machine>,
  machineCategory?: MachineCategory,
  saveMachineCategory: (data: MachineCategory) => void,
}

/**
 * Form to set create/edit machine category
 */
export const MachineCategoryForm: React.FC<MachineCategoryFormProps> = ({ machines, machineCategory, saveMachineCategory }) => {
  const { t } = useTranslation('admin');

  const { handleSubmit, register, control, formState } = useForm<MachineCategory>({ defaultValues: { ...machineCategory } });

  /**
   * Convert all machines to the checklist format
   */
  const buildOptions = (): Array<SelectOption<number>> => {
    return machines.map(t => {
      return { value: t.id, label: t.name };
    });
  };

  /**
   * Callback triggered when the form is submitted: process with the machine category creation or update.
   */
  const onSubmit: SubmitHandler<MachineCategory> = (data: MachineCategory) => {
    saveMachineCategory(data);
  };

  return (
    <div className="machine-category-form">
      <form name="machineCategoryForm" onSubmit={handleSubmit(onSubmit)}>
        <FormInput id="name"
                  register={register}
                  rules={{ required: true }}
                  formState={formState}
                  label={t('app.admin.machine_category_form.name')}
                  />
        <div>
          <h4>{t('app.admin.machine_category_form.assigning_machines')}</h4>
          <FormChecklist options={buildOptions()}
                          control={control}
                          id="machine_ids"
                          formState={formState} />
        </div>
        <div className="main-actions">
          <FabButton type="submit">
            {t('app.admin.machine_category_form.save')}
          </FabButton>
        </div>
      </form>
    </div>
  );
};
