import React from 'react';
import { useForm, SubmitHandler } from 'react-hook-form';
import { AuthenticationProvider } from '../../models/authentication-provider';

interface ProviderFormProps {
  provider?: AuthenticationProvider,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

export const ProviderForm: React.FC<ProviderFormProps> = ({ provider, onError, onSuccess }) => {
  const { handleSubmit } = useForm<AuthenticationProvider>({ defaultValues: { ...provider } });

  const onSubmit: SubmitHandler<AuthenticationProvider> = (data: AuthenticationProvider) => {
    if (data) {
      onSuccess('Provider created successfully');
    } else {
      onError('Failed to created provider');
    }
  };

  return (
    <form className="provider-form" onSubmit={handleSubmit(onSubmit)}>

    </form>
  );
};
