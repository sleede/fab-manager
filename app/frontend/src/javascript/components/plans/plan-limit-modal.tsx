import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { FabAlert } from '../base/fab-alert';
import { FabModal, ModalSize } from '../base/fab-modal';
import { useForm, useWatch } from 'react-hook-form';
import { FormSelect } from '../form/form-select';
import { FormInput } from '../form/form-input';
import { LimitableType, PlanLimitation } from '../../models/plan';
import { Machine } from '../../models/machine';
import { MachineCategory } from '../../models/machine-category';
import { SelectOption } from '../../models/select';
import { FabButton } from '../base/fab-button';
import { useEffect } from 'react';

interface PlanLimitModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: (limit: PlanLimitation) => void,
  machines: Array<Machine>
  categories: Array<MachineCategory>,
  limitation?: PlanLimitation,
  existingLimitations: Array<PlanLimitation>;
}

/**
 * Form to manage subscriptions limitations of use
 */
export const PlanLimitModal: React.FC<PlanLimitModalProps> = ({ isOpen, toggleModal, machines, categories, onSuccess, limitation, existingLimitations = [] }) => {
  const { t } = useTranslation('admin');

  const { register, control, formState, setValue, handleSubmit, reset } = useForm<PlanLimitation>({ defaultValues: limitation || { limitable_type: 'MachineCategory' } });
  const limitType = useWatch({ control, name: 'limitable_type' });

  useEffect(() => {
    reset(limitation);
  }, [limitation]);

  /**
   * Toggle the form between 'categories' and 'machine'
   */
  const toggleLimitType = (evt: React.MouseEvent<HTMLButtonElement, MouseEvent>, type: LimitableType) => {
    evt.preventDefault();
    setValue('limitable_type', type);
    setValue('limitable_id', null);
  };

  /**
   * Callback triggered when the user validates the new limit.
   * We do not use handleSubmit() directly to prevent the propagaion of the "submit" event to the parent form
   */
  const onSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }
    return handleSubmit((data: PlanLimitation) => {
      onSuccess({ ...data, _modified: true });
      reset({ limitable_type: 'MachineCategory', limitable_id: null, limit: null });
      toggleModal();
    })(event);
  };
  /**
   * Creates options to the react-select format
   */
  const buildOptions = (): Array<SelectOption<number>> => {
    if (limitType === 'MachineCategory') {
      return categories
        .filter(c => limitation || !existingLimitations.filter(l => l.limitable_type === 'MachineCategory').map(l => l.limitable_id).includes(c.id))
        .map(cat => {
          return { value: cat.id, label: cat.name };
        });
    } else {
      return machines
        .filter(m => limitation || !existingLimitations.filter(l => l.limitable_type === 'Machine').map(l => l.limitable_id).includes(m.id))
        .map(machine => {
          return { value: machine.id, label: machine.name };
        });
    }
  };

  return (
    <FabModal title={t('app.admin.plan_limit_modal.title')}
              width={ModalSize.large}
              isOpen={isOpen}
              toggleModal={toggleModal}
              onClose={() => reset({ limitable_type: 'MachineCategory' })}
              closeButton>
      <form className='plan-limit-modal' onSubmit={onSubmit}>
        <p className='subtitle'>{t('app.admin.plan_limit_modal.limit_reservations')}</p>
        <div className="grp">
          <button onClick={evt => toggleLimitType(evt, 'MachineCategory')}
                  className={limitType === 'MachineCategory' ? 'is-active' : ''}
                  disabled={!!limitation}>
            {t('app.admin.plan_limit_modal.by_category')}
          </button>
          <button onClick={evt => toggleLimitType(evt, 'Machine')}
                  className={limitType === 'Machine' ? 'is-active' : ''}
                  disabled={!!limitation}>
            {t('app.admin.plan_limit_modal.by_machine')}
          </button>
        </div>
          <FabAlert level='info'>{limitType === 'Machine' ? t('app.admin.plan_limit_modal.machine_info') : t('app.admin.plan_limit_modal.categories_info')}</FabAlert>
          <FormInput register={register} id="id" type="hidden" />
          <FormInput register={register} id="limitable_type" type="hidden" />
          <FormSelect options={buildOptions()}
                      disabled={!!limitation}
                      control={control}
                      id="limitable_id"
                      rules={{ required: true }}
                      formState={formState}
                      label={t('app.admin.plan_limit_modal.machine')} />
        <FormInput id="limit"
                   type="number"
                   register={register}
                   rules={{ required: true, min: 1 }}
                   nullable
                   step={1}
                   formState={formState}
                   label={t('app.admin.plan_limit_modal.max_hours_per_day')} />
        <FabButton type="submit">{t('app.admin.plan_limit_modal.confirm')}</FabButton>
      </form>
    </FabModal>
  );
};
