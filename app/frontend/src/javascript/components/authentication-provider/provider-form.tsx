import React, { useCallback, useEffect, useState } from 'react';
import { useForm, SubmitHandler, useWatch } from 'react-hook-form';
import { react2angular } from 'react2angular';
import { debounce as _debounce } from 'lodash';
import {
  AuthenticationProvider,
  AuthenticationProviderMapping,
  OpenIdConnectProvider,
  ProvidableType
} from '../../models/authentication-provider';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { FormInput } from '../form/form-input';
import { useTranslation } from 'react-i18next';
import { FormSelect } from '../form/form-select';
import { Oauth2Form } from './oauth2-form';
import { DataMappingForm } from './data-mapping-form';
import { FabButton } from '../base/fab-button';
import AuthProviderAPI from '../../api/auth-provider';
import { OpenidConnectForm } from './openid-connect-form';
import { DatabaseForm } from './database-form';

declare const Application: IApplication;

// list of supported authentication methods
const METHODS = {
  DatabaseProvider: 'local_database',
  OAuth2Provider: 'oauth2',
  OpenIdConnectProvider: 'openid_connect'
};

interface ProviderFormProps {
  action: 'create' | 'update',
  provider?: AuthenticationProvider,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

type selectProvidableTypeOption = { value: string, label: string };

/**
 * Form to create or update an authentication provider.
 */
export const ProviderForm: React.FC<ProviderFormProps> = ({ action, provider, onError, onSuccess }) => {
  const { handleSubmit, register, control, formState, setValue } = useForm<AuthenticationProvider>({ defaultValues: { ...provider } });
  const output = useWatch<AuthenticationProvider>({ control });
  const [providableType, setProvidableType] = useState<ProvidableType>(provider?.providable_type);
  const [strategyName, setStrategyName] = useState<string>(provider?.strategy_name);

  const { t } = useTranslation('admin');

  useEffect(() => {
    updateStrategyName(output as AuthenticationProvider);
  }, [output?.providable_type, output?.name]);

  /**
   * Callback triggered when the form is submitted: process with the provider creation or update.
   */
  const onSubmit: SubmitHandler<AuthenticationProvider> = (data: AuthenticationProvider) => {
    AuthProviderAPI[action](data).then(() => {
      onSuccess(t(`app.admin.authentication.provider_form.${action}_success`));
    }).catch(error => {
      onError(error);
    });
  };

  /**
   * Build the list of available authentication methods to match with react-select requirements.
   */
  const buildProvidableTypeOptions = (): Array<selectProvidableTypeOption> => {
    return Object.keys(METHODS).map((method: string) => {
      return { value: method, label: t(`app.admin.authentication.provider_form.methods.${METHODS[method]}`) };
    });
  };

  /**
   * Callback triggered when the providable type is changed.
   * Changing the providable type will change the form to match the new type.
   */
  const onProvidableTypeChange = (type: ProvidableType) => {
    setProvidableType(type);
  };

  /**
   * Request the API the strategy name for the current "in-progress" provider.
   */
  const updateStrategyName = useCallback(_debounce((provider: AuthenticationProvider): void => {
    AuthProviderAPI.strategyName(provider).then(strategyName => {
      setStrategyName(strategyName);
    }).catch(error => {
      onError(error);
    });
  }, 400), []);

  return (
    <form className="provider-form" onSubmit={handleSubmit(onSubmit)}>
      <FormInput id="name"
                 register={register}
                 readOnly={action === 'update'}
                 rules={{ required: true }}
                 label={t('app.admin.authentication.provider_form.name')} />
      <FormSelect id="providable_type"
                  control={control}
                  options={buildProvidableTypeOptions()}
                  label={t('app.admin.authentication.provider_form.authentication_type')}
                  onChange={onProvidableTypeChange}
                  readOnly={action === 'update'}
                  rules={{ required: true }} />
      {providableType === 'DatabaseProvider' && <DatabaseForm register={register} />}
      {providableType === 'OAuth2Provider' && <Oauth2Form register={register} strategyName={strategyName} />}
      {providableType === 'OpenIdConnectProvider' && <OpenidConnectForm register={register}
                                                                        control={control}
                                                                        currentFormValues={output.providable_attributes as OpenIdConnectProvider}
                                                                        formState={formState}
                                                                        setValue={setValue} />}
      {providableType && providableType !== 'DatabaseProvider' && <DataMappingForm register={register}
                                                                                   control={control}
                                                                                   providerType={providableType}
                                                                                   setValue={setValue}
                                                                                   currentFormValues={output.auth_provider_mappings_attributes as Array<AuthenticationProviderMapping>} />}
      <div className="main-actions">
        <FabButton type="submit" className="submit-button">{t('app.admin.authentication.provider_form.save')}</FabButton>
      </div>
    </form>
  );
};

const ProviderFormWrapper: React.FC<ProviderFormProps> = ({ action, provider, onError, onSuccess }) => {
  return (
    <Loader>
      <ProviderForm action={action} provider={provider} onError={onError} onSuccess={onSuccess} />
    </Loader>
  );
};

Application.Components.component('providerForm', react2angular(ProviderFormWrapper, ['action', 'provider', 'onSuccess', 'onError']));
