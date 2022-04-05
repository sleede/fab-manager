import React from 'react';
import { useForm, SubmitHandler } from 'react-hook-form';
import { react2angular } from 'react2angular';
import { AuthenticationProvider } from '../../models/authentication-provider';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { RHFInput } from '../base/rhf-input';
import { useTranslation } from 'react-i18next';
import { FabSelect } from '../base/fab-select';

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

export const ProviderForm: React.FC<ProviderFormProps> = ({ action, provider, onError, onSuccess }) => {
  const { handleSubmit, register, control } = useForm<AuthenticationProvider>({ defaultValues: { ...provider } });
  const { t } = useTranslation('shared');

  const onSubmit: SubmitHandler<AuthenticationProvider> = (data: AuthenticationProvider) => {
    if (data) {
      onSuccess('Provider created successfully');
    } else {
      onError('Failed to created provider');
    }
  };

  const buildProvidableTypeOptions = (): Array<selectProvidableTypeOption> => {
    return Object.keys(METHODS).map((method: string) => {
      return { value: method, label: t(`app.shared.authentication.${METHODS[method]}`) };
    });
  };

  return (
    <form className="provider-form" onSubmit={handleSubmit(onSubmit)}>
      <RHFInput id="name" register={register} readOnly={action === 'update'} rules={{ required: true }} label={t('app.shared.authentication.name')} />
      <FabSelect id="providable_type" control={control} options={buildProvidableTypeOptions()} valueDefault={'DatabaseProvider'} />
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
