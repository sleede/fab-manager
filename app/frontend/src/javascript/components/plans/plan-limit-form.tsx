import { useState } from 'react';
import { Control, FormState } from 'react-hook-form/dist/types/form';
import { FormSwitch } from '../form/form-switch';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';
import { PencilSimple, Trash } from 'phosphor-react';
import { PlanLimitModal } from './plan-limit-modal';

interface PlanLimitFormProps<TContext extends object> {
  control: Control<any, TContext>,
  formState: FormState<any>
}

/**
 * Form tab to manage a subscription's usage limit
 */
export const PlanLimitForm = <TContext extends object> ({ control, formState }: PlanLimitFormProps<TContext>) => {
  const { t } = useTranslation('admin');

  const [isOpen, setIsOpen] = useState<boolean>(false);

  /**
  * Opens/closes the product stock edition modal
  */
  const toggleModal = (): void => {
    setIsOpen(!isOpen);
  };

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
                      id="active_limitation" />
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

      <PlanLimitModal isOpen={isOpen}
                      toggleModal={toggleModal} />
    </div>
  );
};
