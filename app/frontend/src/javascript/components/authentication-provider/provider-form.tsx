import React, { useState } from 'react';
import { useForm, SubmitHandler } from 'react-hook-form';
import { react2angular } from 'react2angular';
import { AuthenticationProvider } from '../../models/authentication-provider';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { FormInput } from '../form/form-input';
import { useTranslation } from 'react-i18next';
import { FormSelect } from '../form/form-select';
import { Oauth2Form } from './oauth2-form';
import { DataMappingForm } from './data-mapping-form';

declare const Application: IApplication;

// list of supported authentication methods
const METHODS = {
  DatabaseProvider: 'local_database',
  OAuth2Provider: 'o_auth2',
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
  const { handleSubmit, register, control } = useForm<AuthenticationProvider>({ defaultValues: { ...provider } });
  const [providableType, setProvidableType] = useState<string>(provider?.providable_type);
  const { t } = useTranslation('shared');

  /**
   * Callback triggered when the form is submitted: process with the provider creation or update.
   */
  const onSubmit: SubmitHandler<AuthenticationProvider> = (data: AuthenticationProvider) => {
    if (data) {
      onSuccess('Provider created successfully');
    } else {
      onError('Failed to created provider');
    }
  };

  /**
   * Build the list of available authentication methods to match with react-select requirements.
   */
  const buildProvidableTypeOptions = (): Array<selectProvidableTypeOption> => {
    return Object.keys(METHODS).map((method: string) => {
      return { value: method, label: t(`app.shared.authentication.${METHODS[method]}`) };
    });
  };

  /**
   * Callback triggered when the providable type is changed.
   * Changing the providable type will change the form to match the new type.
   */
  const onProvidableTypeChange = (type: string) => {
    setProvidableType(type);
  };

  return (
    <form className="provider-form" onSubmit={handleSubmit(onSubmit)}>
      <FormInput id="name"
                 register={register}
                 readOnly={action === 'update'}
                 rules={{ required: true }}
                 label={t('app.shared.authentication.name')} />
      <FormSelect id="providable_type"
                  control={control}
                  options={buildProvidableTypeOptions()}
                  label={t('app.shared.authentication.authentication_type')}
                  onChange={onProvidableTypeChange}
                  rules={{ required: true }} />
      {providableType === 'OAuth2Provider' && <Oauth2Form register={register} />}
      {providableType && providableType !== 'DatabaseProvider' && <DataMappingForm register={register} control={control} />}
      <input type={'submit'} />
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
