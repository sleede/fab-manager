import { useEffect, useState } from 'react';
import * as React from 'react';
import { SubmitHandler, useForm, useWatch } from 'react-hook-form';
import { Interval, Plan } from '../../models/plan';
import { useTranslation } from 'react-i18next';
import { FormInput } from '../form/form-input';
import PlanAPI from '../../api/plan';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { ErrorBoundary } from '../base/error-boundary';
import GroupAPI from '../../api/group';
import { SelectOption } from '../../models/select';
import { FormSelect } from '../form/form-select';
import { FormSwitch } from '../form/form-switch';
import PlanCategoryAPI from '../../api/plan-category';
import FormatLib from '../../lib/format';
import { FabAlert } from '../base/fab-alert';
import { FormRichText } from '../form/form-rich-text';
import { FormFileUpload } from '../form/form-file-upload';
import UserAPI from '../../api/user';
import { FabButton } from '../base/fab-button';
import { UserPlus } from 'phosphor-react';
import { PartnerModal } from './partner-modal';
import { PlanPricingForm } from './plan-pricing-form';
import { AdvancedAccountingForm } from '../accounting/advanced-accounting-form';
import { FabTabs } from '../base/fab-tabs';

declare const Application: IApplication;

interface PlanFormProps {
  action: 'create' | 'update',
  plan?: Plan,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  beforeSubmit?: (data: Plan) => void,
}

/**
 * Form to edit or create subscription plans
 */
export const PlanForm: React.FC<PlanFormProps> = ({ action, plan, onError, onSuccess, beforeSubmit }) => {
  const { handleSubmit, register, control, formState, setValue } = useForm<Plan>({ defaultValues: { ...plan } });
  const output = useWatch<Plan>({ control }); // eslint-disable-line
  const { t } = useTranslation('admin');

  const [groups, setGroups] = useState<Array<SelectOption<number>>>(null);
  const [categories, setCategories] = useState<Array<SelectOption<number>>>(null);
  const [allGroups, setAllGroups] = useState<boolean>(false);
  const [partners, setPartners] = useState<Array<SelectOption<number>>>(null);
  const [isOpenPartnerModal, setIsOpenPartnerModal] = useState<boolean>(false);

  useEffect(() => {
    GroupAPI.index({ disabled: false })
      .then(res => setGroups(res.map(g => { return { value: g.id, label: g.name }; })))
      .catch(onError);
    PlanCategoryAPI.index()
      .then(res => setCategories(res.map(c => { return { value: c.id, label: c.name }; })))
      .catch(onError);
    UserAPI.index({ role: 'partner' })
      .then(res => setPartners(res.map(p => { return { value: p.id, label: p.name }; })))
      .catch(onError);
  }, []);

  /**
   * Callback triggered when the user validates the plan form: handle create or update
   */
  const onSubmit: SubmitHandler<Plan> = (data: Plan) => {
    if (typeof beforeSubmit === 'function') beforeSubmit(data);
    PlanAPI[action](data).then(() => {
      onSuccess(t(`app.admin.plan_form.${action}_success`));
      window.location.href = '/#!/admin/pricing';
    }).catch(error => {
      onError(error);
    });
  };

  /**
   * Callback triggered when the user switches the 'all group' button.
   */
  const handleAllGroupsChange = (checked: boolean) => {
    setAllGroups(checked);
    if (checked) {
      setValue('group_id', 'all');
    } else {
      setValue('group_id', null);
    }
  };

  /**
   * Callback triggere when the user switches the 'partner plan' button.
   */
  const handlePartnershipChange = (checked: boolean) => {
    if (checked) {
      setValue('type', 'PartnerPlan');
    } else {
      setValue('type', 'Plan');
    }
  };

  /**
   * Return the available options for the plan period
   */
  const buildPeriodsOptions = (): Array<SelectOption<string>> => {
    return ['week', 'month', 'year'].map(d => { return { value: d, label: t(`app.admin.plan_form.${d}`) }; });
  };

  /**
   * Callback triggered when the user changes the period of the current plan
   */
  const handlePeriodUpdate = (period: Interval) => {
    if (period === 'week') {
      setValue('monthly_payment', false);
    }
  };

  /**
   * Open/closes the partner creation modal
   */
  const tooglePartnerModal = () => {
    setIsOpenPartnerModal(!isOpenPartnerModal);
  };

  /**
   * Callback triggered when a user with role partner was created in the dedicated modal form
   */
  const handleNewPartner = (user) => {
    tooglePartnerModal();
    onSuccess(t('app.admin.plan_form.partner_created'));
    partners.push({ value: user.id, label: user.name });
    setValue('partner_id', user.id);
  };

  /**
   * Render the content of the 'subscriptions settings' tab
   */
  const renderSettingsTab = () => (
    <div className='plan-form-content'>
      <section>
        <header>
          <p className="title">{t('app.admin.plan_form.description')}</p>
        </header>
        <div className="content">
          <FormInput register={register}
                     id="base_name"
                     formState={formState}
                     rules={{
                       required: true,
                       maxLength: { value: 24, message: t('app.admin.plan_form.name_max_length') }
                     }}
                     label={t('app.admin.plan_form.name')} />
          <FormRichText control={control}
                        formState={formState}
                        id="description"
                        label={t('app.admin.plan_form.description')}
                        limit={200}
                        heading link blockquote />
          <FormFileUpload setValue={setValue}
                          register={register}
                          formState={formState}
                          defaultFile={output.plan_file_attributes}
                          id="plan_file_attributes"
                          className="plan-sheet"
                          label={t('app.admin.plan_form.information_sheet')} />
        </div>
      </section>

      <section>
        <header>
          <p className="title">{t('app.admin.plan_form.general_settings')}</p>
          <p className="description">{t('app.admin.plan_form.general_settings_info')}</p>
        </header>
        <div className="content">
          {action === 'create' && <FormSwitch control={control}
                                              formState={formState}
                                              onChange={handleAllGroupsChange}
                                              defaultValue={false}
                                              label={t('app.admin.plan_form.transversal')}
                                              tooltip={t('app.admin.plan_form.transversal_help')}
                                              id="all_groups" />}
          {!allGroups && groups && <FormSelect options={groups}
                                                formState={formState}
                                                control={control}
                                                rules={{ required: !allGroups }}
                                                disabled={action === 'update'}
                                                label={t('app.admin.plan_form.group')}
                                                id="group_id" />}
          <div className="grp">
            <FormInput register={register}
                       rules={{ required: true, min: 1 }}
                       disabled={action === 'update'}
                       formState={formState}
                       label={t('app.admin.plan_form.number_of_periods')}
                       type="number"
                       id="interval_count" />
            <FormSelect options={buildPeriodsOptions()}
                        control={control}
                        disabled={action === 'update'}
                        onChange={handlePeriodUpdate}
                        id="interval"
                        label={t('app.admin.plan_form.period')}
                        formState={formState}
                        rules={{ required: true }} />
          </div>
          <FormInput register={register}
                     formState={formState}
                     id="amount"
                     type="number"
                     step={0.01}
                     addOn={FormatLib.currencySymbol()}
                     rules={{ required: true, min: 0 }}
                     label={t('app.admin.plan_form.subscription_price')} />
        </div>
      </section>

      <section>
        <header>
          <p className="title">{t('app.admin.plan_form.activation_and_payment')}</p>
        </header>
        <div className="content">
          <FormSwitch control={control}
                      formState={formState}
                      id="disabled"
                      defaultValue={false}
                      label={t('app.admin.plan_form.disabled')}
                      tooltip={t('app.admin.plan_form.disabled_help')} />
          <FormSwitch control={control}
                      formState={formState}
                      id="is_rolling"
                      label={t('app.admin.plan_form.rolling_subscription')}
                      disabled={action === 'update'}
                      tooltip={t('app.admin.plan_form.rolling_subscription_help')} />
          <FormSwitch control={control}
                      formState={formState}
                      id="monthly_payment"
                      label={t('app.admin.plan_form.monthly_payment')}
                      disabled={action === 'update' || output.interval === 'week'}
                      tooltip={t('app.admin.plan_form.monthly_payment_help')} />
        </div>
      </section>

      <section>
        <header>
          <p className="title">{t('app.admin.plan_form.partnership')}</p>
          <p className="description">{t('app.admin.plan_form.partner_plan_help')}</p>
        </header>
        <div className="content">
          <FormSwitch control={control}
                      id="partnership"
                      disabled={action === 'update'}
                      defaultValue={plan?.type === 'PartnerPlan'}
                      onChange={handlePartnershipChange}
                      formState={formState}
                      label={t('app.admin.plan_form.partner_plan')} />
          <FormInput register={register} type="hidden" id="type" defaultValue="Plan" />
          {output.type === 'PartnerPlan' && <div className="partner">
            {partners && <FormSelect id="partner_id"
                                      options={partners}
                                      control={control}
                                      formState={formState}
                                      rules={{ required: output.type === 'PartnerPlan' }}
                                      tooltip={t('app.admin.plan_form.alert_partner_notification')}
                                      label={t('app.admin.plan_form.notified_partner')} />}
            <FabButton className="is-secondary" icon={<UserPlus size={20} />} onClick={tooglePartnerModal}>
              {t('app.admin.plan_form.new_user')}
            </FabButton>
          </div>}
        </div>
      </section>

      {categories?.length > 0 && <FormSelect options={categories}
                                             formState={formState}
                                             control={control}
                                             id="plan_category_id"
                                             tooltip={t('app.admin.plan_form.category_help')}
                                             label={t('app.admin.plan_form.category')} />}
      {action === 'update' && <FabAlert level="warning">
        {t('app.admin.plan_form.edit_amount_info')}
      </FabAlert>}

      <FormInput register={register}
                  formState={formState}
                  id="ui_weight"
                  type="number"
                  label={t('app.admin.plan_form.visual_prominence')}
                  tooltip={t('app.admin.plan_form.visual_prominence_help')} />

      <AdvancedAccountingForm register={register} onError={onError} />
      {action === 'update' && <PlanPricingForm formState={formState}
                                                control={control}
                                                onError={onError}
                                                setValue={setValue}
                                                register={register} />}
    </div>
  );

  return (
    <div className="plan-form">
      <header>
        <h2>{t('app.admin.plan_form.ACTION_title', { ACTION: action })}</h2>
        <div className="grpBtn">
          <FabButton type="submit" onClick={handleSubmit(onSubmit)} className="fab-button is-main">
            {t('app.admin.plan_form.save')}
          </FabButton>
        </div>
      </header>

      <form onSubmit={handleSubmit(onSubmit)}>
        <FabTabs tabs={[
          {
            id: 'settings',
            title: t('app.admin.plan_form.tab_settings'),
            content: renderSettingsTab()
          },
          {
            id: 'usageLimits',
            title: t('app.admin.plan_form.tab_usage_limits'),
            content: <pre>plop</pre>
          }
        ]} />
      </form>

      <PartnerModal isOpen={isOpenPartnerModal}
                    toggleModal={tooglePartnerModal}
                    onError={onError}
                    onPartnerCreated={handleNewPartner} />
    </div>
  );
};

const PlanFormWrapper: React.FC<PlanFormProps> = (props) => {
  return (
    <Loader>
      <ErrorBoundary>
        <PlanForm {...props} />
      </ErrorBoundary>
    </Loader>
  );
};
Application.Components.component('planForm', react2angular(PlanFormWrapper, ['action', 'plan', 'onError', 'onSuccess']));
