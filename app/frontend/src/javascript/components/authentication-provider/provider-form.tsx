import React from 'react';
import { useForm, SubmitHandler } from 'react-hook-form';
import { react2angular } from 'react2angular';
import { AuthenticationProvider } from '../../models/authentication-provider';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { RHFInput } from '../base/rhf-input';

declare const Application: IApplication;

interface ProviderFormProps {
  provider?: AuthenticationProvider,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

export const ProviderForm: React.FC<ProviderFormProps> = ({ provider, onError, onSuccess }) => {
  const { handleSubmit, register } = useForm<AuthenticationProvider>({ defaultValues: { ...provider } });

  const onSubmit: SubmitHandler<AuthenticationProvider> = (data: AuthenticationProvider) => {
    if (data) {
      onSuccess('Provider created successfully');
    } else {
      onError('Failed to created provider');
    }
  };

  return (
    <form className="provider-form" onSubmit={handleSubmit(onSubmit)}>
      <RHFInput id="provider_name" register={register} />
    </form>
  );
};

const ProviderFormWrapper: React.FC<ProviderFormProps> = ({ provider, onError, onSuccess }) => {
  return (
    <Loader>
      <ProviderForm provider={provider} onError={onError} onSuccess={onSuccess} />
    </Loader>
  );
};

Application.Components.component('providerForm', react2angular(ProviderFormWrapper, ['provider', 'onSuccess', 'onError']));
