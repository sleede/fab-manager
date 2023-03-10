import { ReactNode, useEffect, useState } from 'react';
import { Control, FormState, UseFormGetValues, UseFormResetField } from 'react-hook-form/dist/types/form';
import { FormSwitch } from '../form/form-switch';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import { PlanLimitModal } from './plan-limit-modal';
import { Plan, PlanLimitation } from '../../models/plan';
import { useFieldArray, UseFormRegister, useWatch } from 'react-hook-form';
import { Machine } from '../../models/machine';
import { MachineCategory } from '../../models/machine-category';
import MachineAPI from '../../api/machine';
import MachineCategoryAPI from '../../api/machine-category';
import { FormUnsavedList } from '../form/form-unsaved-list';
import { EditDestroyButtons } from '../base/edit-destroy-buttons';
import PlanLimitationAPI from '../../api/plan-limitation';

interface PlanLimitFormProps<TContext extends object> {
  register: UseFormRegister<Plan>,
  control: Control<Plan, TContext>,
  formState: FormState<Plan>,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  getValues: UseFormGetValues<Plan>,
  resetField: UseFormResetField<Plan>
}

/**
 * Form tab to manage a subscription's usage limit
 */
export const PlanLimitForm = <TContext extends object> ({ register, control, formState, onError, onSuccess, getValues, resetField }: PlanLimitFormProps<TContext>) => {
  const { t } = useTranslation('admin');
  const { fields, append, remove, update } = useFieldArray<Plan, 'plan_limitations_attributes'>({ control, name: 'plan_limitations_attributes' });
  const limiting = useWatch<Plan>({ control, name: 'limiting' });

  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [machines, setMachines] = useState<Array<Machine>>([]);
  const [categories, setCategories] = useState<Array<MachineCategory>>([]);
  const [edited, setEdited] = useState<{index: number, limitation: PlanLimitation}>(null);

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
  const onLimitationSuccess = (limitation: PlanLimitation): void => {
    const id = getValues(`plan_limitations_attributes.${edited?.index}.id`);
    if (id) {
      update(edited.index, { ...limitation, id });
      setEdited(null);
    } else {
      append({ ...limitation });
    }
  };

  /**
   * Triggered when an unsaved limit was removed from the "pending" list.
   */
  const onRemoveUnsaved = (index: number): void => {
    const id = getValues(`plan_limitations_attributes.${index}.id`);
    if (id) {
      // will reset the field to its default values
      resetField(`plan_limitations_attributes.${index}`);
      // unmount and remount the field
      update(index, getValues(`plan_limitations_attributes.${index}`));
    } else {
      remove(index);
    }
  };

  /**
   * Callback triggered when the limitation was deleted. Return a callback accepting a message
   */
  const onLimitationDeleted = (index: number): (message: string) => void => {
    return (message: string) => {
      onSuccess(message);
      remove(index);
    };
  };

  /**
   * Callback triggered when the user wants to modify a limitation. Return a callback
   */
  const onEditLimitation = (limitation: PlanLimitation, index: number): () => void => {
    return () => {
      setEdited({ index, limitation });
      toggleModal();
    };
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

      {limiting && <div className="plan-limit-grp">
        <header>
          <p>{t('app.admin.plan_limit_form.all_limitations')}</p>
          <div className="grpBtn">
            <FabButton onClick={toggleModal} className="is-main">
              {t('app.admin.plan_limit_form.new_usage_limitation')}
            </FabButton>
          </div>
        </header>
        <FormUnsavedList fields={fields}
                         onRemove={onRemoveUnsaved}
                         register={register}
                         title={t('app.admin.plan_limit_form.ongoing_limitations')}
                         shouldRenderField={(limit: PlanLimitation) => limit._modified}
                         formAttributeName="plan_limitations_attributes"
                         formAttributes={['id', 'limitable_type', 'limitable_id', 'limit']}
                         renderField={renderOngoingLimit}
                         cancelLabel={t('app.admin.plan_limit_form.cancel')} />

        {fields.filter(f => f._modified).length > 0 &&
          <p className="title">{t('app.admin.plan_limit_form.saved_limitations')}</p>
        }

        {fields.filter(f => f.limitable_type === 'MachineCategory' && !f._modified).length > 0 &&
          <div className='plan-limit-list'>
            <p className="title">{t('app.admin.plan_limit_form.by_categories')}</p>
            {fields.map((limitation, index) => {
              if (limitation.limitable_type !== 'MachineCategory' || limitation._modified) return false;

              return (
                <div className="plan-limit-item" key={limitation.id}>
                  <div className="grp">
                    <div>
                      <span>{t('app.admin.plan_limit_form.category')}</span>
                      <p>{categories.find(c => c.id === limitation.limitable_id)?.name}</p>
                    </div>
                    <div>
                      <span>{t('app.admin.plan_limit_form.max_hours_per_day')}</span>
                      <p>{limitation.limit}</p>
                    </div>
                  </div>

                  <div className='actions'>
                    <EditDestroyButtons onDeleteSuccess={onLimitationDeleted(index)}
                                        onError={onError}
                                        onEdit={onEditLimitation(limitation, index)}
                                        itemId={limitation.id}
                                        itemType={t('app.admin.plan_limit_form.limitation')}
                                        apiDestroy={PlanLimitationAPI.destroy} />
                  </div>
                </div>
              );
            }).filter(Boolean)}
          </div>
        }

        {fields.filter(f => f.limitable_type === 'Machine' && !f._modified).length > 0 &&
          <div className='plan-limit-list'>
            <p className="title">{t('app.admin.plan_limit_form.by_machine')}</p>
            {fields.map((limitation, index) => {
              if (limitation.limitable_type !== 'Machine' || limitation._modified) return false;

              return (
                <div className="plan-limit-item" key={limitation.id}>
                  <div className="grp">
                    <div>
                      <span>{t('app.admin.plan_limit_form.machine')}</span>
                      <p>{machines.find(m => m.id === limitation.limitable_id)?.name}</p>
                    </div>
                    <div>
                      <span>{t('app.admin.plan_limit_form.max_hours_per_day')}</span>
                      <p>{limitation.limit}</p>
                    </div>
                  </div>

                  <div className='actions'>
                    <EditDestroyButtons onDeleteSuccess={onLimitationDeleted(index)}
                                        onError={onError}
                                        onEdit={onEditLimitation(limitation, index)}
                                        itemId={limitation.id}
                                        itemType={t('app.admin.plan_limit_form.limitation')}
                                        apiDestroy={PlanLimitationAPI.destroy} />
                  </div>
                </div>
              );
            }).filter(Boolean)}
          </div>
        }
      </div>}

      <PlanLimitModal isOpen={isOpen}
                      machines={machines}
                      categories={categories}
                      toggleModal={toggleModal}
                      onSuccess={onLimitationSuccess}
                      limitation={edited?.limitation} />
    </div>
  );
};
