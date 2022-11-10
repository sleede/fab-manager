import React, { useEffect, useState } from 'react';
import { SubmitHandler, useForm, useWatch } from 'react-hook-form';
import { Plan } from '../../models/plan';
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

declare const Application: IApplication;

interface PlanFormProps {
  action: 'create' | 'update',
  plan?: Plan,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Form to edit or create subscription plans
 */
export const PlanForm: React.FC<PlanFormProps> = ({ action, plan, onError, onSuccess }) => {
  const { handleSubmit, register, control, formState, setValue } = useForm<Plan>({ defaultValues: { ...plan } });
  const _output = useWatch<Plan>({ control }); // eslint-disable-line
  const { t } = useTranslation('admin');

  const [groups, setGroups] = useState<Array<SelectOption<number>>>(null);
  const [allGroups, setAllGroups] = useState<boolean>(false);

  useEffect(() => {
    GroupAPI.index({ disabled: false })
      .then(res => setGroups(res.map(g => { return { value: g.id, label: g.name }; })))
      .catch(onError);
  }, []);

  /**
   * Callback triggered when the user validates the plan form: handle create or update
   */
  const onSubmit: SubmitHandler<Plan> = (data: Plan) => {
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

  return (
    <form className="plan-form" onSubmit={handleSubmit(onSubmit)}>
      <h4>{t('app.admin.plan_form.general_information')}</h4>
      <FormInput register={register}
                 id="base_name"
                 formState={formState}
                 rules={{ required: true, maxLength: { value: 24, message: t('app.admin.plan_form.name_max_length') } }}
                 label={t('app.admin.plan_form.name')} />
      <FormSwitch control={control}
                  onChange={handleAllGroupsChange}
                  defaultValue={false}
                  label={t('app.admin.plan_form.transversal')}
                  tooltip={t('app.admin.plan_form.transversal_help')}
                  id="all_groups" />
      {!allGroups && groups && <FormSelect options={groups}
                                           control={control}
                                           rules={{ required: !allGroups }}
                                           label={t('app.admin.plan_form.group')}
                                           id="group_id" />}
    </form>
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
