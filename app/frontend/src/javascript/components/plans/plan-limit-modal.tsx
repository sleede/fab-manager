import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { FabAlert } from '../base/fab-alert';
import { FabModal, ModalSize } from '../base/fab-modal';
import { useForm } from 'react-hook-form';
import { FormSelect } from '../form/form-select';
import { FormInput } from '../form/form-input';

type typeSelectOption = { value: any, label: string };
interface PlanLimitModalProps {
  isOpen: boolean,
  toggleModal: () => void,
}

/**
 * Form to manage subscriptions limitations of use
 */
export const PlanLimitModal: React.FC<PlanLimitModalProps> = ({ isOpen, toggleModal }) => {
  const { t } = useTranslation('admin');

  const { register, control, formState } = useForm<any>();
  const [limitType, setLimitType] = React.useState<'categories' | 'machine'>('categories');

  /**
   * Toggle the form between 'categories' and 'machine'
   */
  const toggleLimitType = (evt: React.MouseEvent<HTMLButtonElement, MouseEvent>, type: 'categories' | 'machine') => {
    evt.preventDefault();
    setLimitType(type);
  };

  /**
   * Creates options to the react-select format
   */
  const buildMachinesCategoriesOptions = (): Array<typeSelectOption> => {
    return [
      { value: '0', label: 'yep' },
      { value: '1', label: 'nope' }
    ];
  };
  /**
   * Creates options to the react-select format
   */
  const buildMachinesOptions = (): Array<typeSelectOption> => {
    return [
      { value: '0', label: 'pif' },
      { value: '1', label: 'paf' },
      { value: '2', label: 'pouf' }
    ];
  };

  return (
    <FabModal title={t('app.admin.plan_limit_modal.title')}
              width={ModalSize.large}
              isOpen={isOpen}
              toggleModal={toggleModal}
              closeButton>
      <form className='plan-limit-modal'>
        <p className='subtitle'>{t('app.admin.plan_limit_modal.limit_reservations')}</p>
        <div className="grp">
          <button onClick={evt => toggleLimitType(evt, 'categories')}
            className={limitType === 'categories' ? 'is-active' : ''}>
              {t('app.admin.plan_limit_modal.by_categories')}
          </button>
          <button onClick={evt => toggleLimitType(evt, 'machine')}
            className={limitType === 'machine' ? 'is-active' : ''}>
              {t('app.admin.plan_limit_modal.by_machine')}
          </button>
        </div>
        {limitType === 'categories' && <>
          <FabAlert level='info'>{t('app.admin.plan_limit_modal.categories_info')}</FabAlert>
          <FormSelect options={buildMachinesCategoriesOptions()}
                      control={control}
                      id="machines_category"
                      rules={{ required: limitType === 'categories' }}
                      formState={formState}
                      label={t('app.admin.plan_limit_modal.category')} />
        </>}
        {limitType === 'machine' && <>
          <FabAlert level='info'>{t('app.admin.plan_limit_modal.machine_info')}</FabAlert>
          <FormSelect options={buildMachinesOptions()}
                      control={control}
                      id="machine"
                      rules={{ required: limitType === 'machine' }}
                      formState={formState}
                      label={t('app.admin.plan_limit_modal.machine')} />
        </>}
        <FormInput id="hours_limit"
                   type="number"
                   register={register}
                   rules={{ required: true, min: 1 }}
                   step={1}
                   formState={formState}
                   label={t('app.admin.plan_limit_modal.max_hours_per_day')} />
      </form>
    </FabModal>
  );
};
