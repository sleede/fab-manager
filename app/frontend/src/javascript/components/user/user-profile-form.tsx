import React from 'react';
import { react2angular } from 'react2angular';
import { SubmitHandler, useForm } from 'react-hook-form';
import { User } from '../../models/user';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { FormInput } from '../form/form-input';

declare const Application: IApplication;

interface UserProfileFormProps {
  action: 'create' | 'update',
  user: User;
  className?: string;
}

export const UserProfileForm: React.FC<UserProfileFormProps> = ({ action, user, className }) => {
  const { handleSubmit, register } = useForm<User>({ defaultValues: { ...user } });

  /**
   * Callback triggered when the form is submitted: process with the user creation or update.
   */
  const onSubmit: SubmitHandler<User> = (data: User) => {
    console.log(action, data);
  };

  return (
    <form className={`user-profile-form ${className}`} onSubmit={handleSubmit(onSubmit)}>
      <FormInput id="email" register={register} rules={{ required: true }} label="email" />
    </form>
  );
};

const UserProfileFormWrapper: React.FC<UserProfileFormProps> = (props) => {
  return (
    <Loader>
      <UserProfileForm {...props} />
    </Loader>
  );
};

Application.Components.component('userProfileForm', react2angular(UserProfileFormWrapper, ['action', 'user', 'className']));
