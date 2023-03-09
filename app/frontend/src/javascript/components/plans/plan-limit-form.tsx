import { ReactNode, useEffect, useState } from 'react';
import { Control, FormState } from 'react-hook-form/dist/types/form';
import { FormSwitch } from '../form/form-switch';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import { PencilSimple, Trash } from 'phosphor-react';
import { PlanLimitModal } from './plan-limit-modal';
import { Plan, PlanLimitation } from '../../models/plan';
import { useFieldArray, UseFormRegister } from 'react-hook-form';
import { Machine } from '../../models/machine';
import { MachineCategory } from '../../models/machine-category';
import MachineAPI from '../../api/machine';
import MachineCategoryAPI from '../../api/machine-category';
import { FormUnsavedList } from '../form/form-unsaved-list';

interface PlanLimitFormProps<TContext extends object> {
  register: UseFormRegister<Plan>,
  control: Control<Plan, TContext>,
  formState: FormState<Plan>,
  onError: (message: string) => void,
}

/**
 * Form tab to manage a subscription's usage limit
 */
export const PlanLimitForm = <TContext extends object> ({ register, control, formState, onError }: PlanLimitFormProps<TContext>) => {
  const { t } = useTranslation('admin');
  const { fields, append, remove } = useFieldArray<Plan, 'plan_limitations_attributes'>({ control, name: 'plan_limitations_attributes' });

  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [machines, setMachines] = useState<Array<Machine>>([]);
  const [categories, setCategories] = useState<Array<MachineCategory>>([]);

  useEffect(() => {
    MachineAPI.index({ disabled: false })
      .then(setMachines)
      .catch(onError);
    MachineCategoryAPI.index()
      .then(setCategories)
      .catch(onError);
  }, []);

  /**
  * Opens/closes the product stock edition modal
  */
  const toggleModal = (): void => {
    setIsOpen(!isOpen);
  };

  /**
   * Triggered when a new limit was added or an existing limit was modified
   */
  const onPlanLimitSuccess = (planLimit: PlanLimitation): void => {
    append({ ...planLimit });
  };

  /**
   * Render an unsaved limitation of use
   */
  const renderOngoingLimit = (limit: PlanLimitation): ReactNode => (
    <>
      {(limit.limitable_type === 'MachineCategory' && <div className="group">
        <span>{t('app.admin.plan_limit_form.category')}</span>
        <p>{categories?.find(c => c.id === limit.limitable_id)?.name}</p>
      </div>) ||
      <div className="group">
        <span>{t('app.admin.plan_limit_form.machine')}</span>
        <p>{machines?.find(m => m.id === limit.limitable_id)?.name}</p>
      </div>}
      <div className="group">
        <span>{t('app.admin.plan_limit_form.max_hours_per_day')}</span>
        <p>{limit.limit}</p>
      </div>
    </>
  );

  return (
    <div className="plan-limit-form">
      <section>
        <header>
          <p className="title">{t('app.admin.plan_limit_form.usage_limitation')}</p>
          <p className="description">{t('app.admin.plan_limit_form.usage_limitation_info')}</p>
        </header>
        <div className="content">
          <FormSwitch control={control}
                      formState={formState}
                      defaultValue={false}
                      label={t('app.admin.plan_limit_form.usage_limitation_switch')}
                      id="limiting" />
        </div>
      </section>

      <div className="plan-limit-grp">
        <header>
          <p>{t('app.admin.plan_limit_form.all_limitations')}</p>
          <div className="grpBtn">
            <FabButton onClick={toggleModal} className="is-main">
              {t('app.admin.plan_limit_form.new_usage_limitation')}
            </FabButton>
          </div>
        </header>

        <div className='plan-limit-list'>
          <p className="title">{t('app.admin.plan_limit_form.by_categories')}</p>
          <div className="plan-limit-item">
            <div className="grp">
              <div>
                <span>{t('app.admin.plan_limit_form.category')}</span>
                <p>Plop</p>
              </div>
              <div>
                <span>{t('app.admin.plan_limit_form.max_hours_per_day')}</span>
                <p>5</p>
              </div>
            </div>

            <div className='actions'>
              <div className='grpBtn'>
                {/* TODO, use <EditDestroyButtons> */}
                <FabButton className='edit-btn'>
                  <PencilSimple size={20} weight="fill" />
                </FabButton>
                <FabButton className='delete-btn'>
                  <Trash size={20} weight="fill" />
                </FabButton>
              </div>
            </div>
          </div>
        </div>

        <FormUnsavedList fields={fields}
                         remove={remove}
                         register={register}
                         title={t('app.admin.plan_limit_form.ongoing_limitations')}
                         shouldRenderField={(limit: PlanLimitation) => limit.limitable_type === 'MachineCategory'}
                         formAttributeName="plan_limitations_attributes"
                         formAttributes={['limitable_id', 'limit']}
                         renderField={renderOngoingLimit}
                         cancelLabel={t('app.admin.plan_limit_form.cancel')} />

        <div className='plan-limit-list'>
          <p className="title">{t('app.admin.plan_limit_form.by_machine')}</p>
          <div className="plan-limit-item">
            <div className="grp">
              <div>
                <span>{t('app.admin.plan_limit_form.machine')}</span>
                <p>Pouet</p>
              </div>
              <div>
                <span>{t('app.admin.plan_limit_form.max_hours_per_day')}</span>
                <p>5</p>
              </div>
            </div>

            <div className='actions'>
              <div className='grpBtn'>
                <FabButton className='edit-btn'>
                  <PencilSimple size={20} weight="fill" />
                </FabButton>
                <FabButton className='delete-btn'>
                  <Trash size={20} weight="fill" />
                </FabButton>
              </div>
            </div>
          </div>
        </div>
      </div>

      <FormUnsavedList fields={fields}
                       remove={remove}
                       register={register}
                       title={t('app.admin.plan_limit_form.ongoing_limit')}
                       shouldRenderField={(limit: PlanLimitation) => limit.limitable_type === 'Machine'}
                       formAttributeName="plan_limitations_attributes"
                       formAttributes={['limitable_id', 'limit']}
                       renderField={renderOngoingLimit}
                       saveReminderLabel={t('app.admin.plan_limit_form.save_reminder')}
                       cancelLabel={t('app.admin.plan_limit_form.cancel')} />

      <PlanLimitModal isOpen={isOpen}
                      machines={machines}
                      categories={categories}
                      toggleModal={toggleModal}
                      onSuccess={onPlanLimitSuccess} />
    </div>
  );
};
