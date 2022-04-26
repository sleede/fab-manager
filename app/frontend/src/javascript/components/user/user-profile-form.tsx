import React from 'react';
import { react2angular } from 'react2angular';
import { SubmitHandler, useForm, useWatch } from 'react-hook-form';
import { User } from '../../models/user';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { FormInput } from '../form/form-input';
import { useTranslation } from 'react-i18next';
import { Avatar } from './avatar';
import { GenderInput } from './gender-input';
import { ChangePassword } from './change-password';
import Switch from 'react-switch';
import { PasswordInput } from './password-input';

declare const Application: IApplication;

interface UserProfileFormProps {
  action: 'create' | 'update',
  size?: 'small' | 'large',
  user: User,
  className?: string,
  onError: (message: string) => void,
}

export const UserProfileForm: React.FC<UserProfileFormProps> = ({ action, size, user, className, onError }) => {
  const { t } = useTranslation('shared');

  const { handleSubmit, register, control, formState } = useForm<User>({ defaultValues: { ...user } });
  const output = useWatch<User>({ control });

  const [isOrganization, setIsOrganization] = React.useState<boolean>(user.invoicing_profile.organization !== null);

  /**
   * Callback triggered when the form is submitted: process with the user creation or update.
   */
  const onSubmit: SubmitHandler<User> = (data: User) => {
    console.log(action, data);
  };

  return (
    <form className={`user-profile-form user-profile-form--${size} ${className}`} onSubmit={handleSubmit(onSubmit)}>
      <div className="avatar-group">
        <Avatar user={user}/>
      </div>
      <div className="fields-group">
        <div className="personnal-data">
          <h4>{t('app.shared.user_profile_form.personal_data')}</h4>
          <GenderInput register={register} />
          <div className="names">
            <FormInput id="profile_attributes.last_name"
                       register={register}
                       rules={{ required: true }}
                       formState={formState}
                       label={t('app.shared.user_profile_form.surname')} />
            <FormInput id="profile_attributes.first_name"
                       register={register}
                       rules={{ required: true }}
                       formState={formState}
                       label={t('app.shared.user_profile_form.first_name')} />
          </div>
          <div className="birth-phone">
            <FormInput id="statistic_profile_attributes.birthday"
                       register={register}
                       label={t('app.shared.user_profile_form.date_of_birth')}
                       type="date" />
            <FormInput id="profile_attributes.phone"
                       register={register}
                       rules={{
                         pattern: {
                           value: /^((00|\+)[0-9]{2,3})?[0-9]{4,14}$/,
                           message: t('app.shared.user_profile_form.phone_number_invalid')
                         }
                       }}
                       formState={formState}
                       label={t('app.shared.user_profile_form.phone_number')} />
          </div>
          <div className="address">
            <FormInput id="invoicing_profile_attributes.address_attributes.id"
                       register={register}
                       type="hidden" />
            <FormInput id="invoicing_profile_attributes.address_attributes.address"
                       register={register}
                       label={t('app.shared.user_profile_form.address')} />
          </div>
        </div>
        <div className="account-data">
          <h4>{t('app.shared.user_profile_form.account_data')}</h4>
          <FormInput id="username"
                     register={register}
                     rules={{ required: true }}
                     formState={formState}
                     label={t('app.shared.user_profile_form.pseudonym')} />
          <FormInput id="email"
                     register={register}
                     rules={{ required: true }}
                     formState={formState}
                     label={t('app.shared.user_profile_form.email_address')} />
          {/* TODO: no password change if sso */}
          {action === 'update' && <ChangePassword register={register}
                                                  onError={onError}
                                                  currentFormPassword={output.password}
                                                  formState={formState} />}
          {action === 'create' && <PasswordInput register={register}
                                                 currentFormPassword={output.password}
                                                 formState={formState} />}
        </div>
        <div className="organization-data">
          <h4>{t('app.shared.user_profile_form.organization_data')}</h4>
          <label className="organization-toggle">
            <p>{t('app.shared.user_profile_form.declare_organization')}</p>
            <Switch checked={isOrganization} onChange={setIsOrganization} />
          </label>
          {isOrganization && <div className="organization-fields">
            <FormInput id="invoicing_profile_attributes.organization_attributes.id"
                       register={register}
                       type="hidden" />
            <FormInput id="invoicing_profile_attributes.organization_attributes.name"
                       register={register}
                       rules={{ required: isOrganization }}
                       formState={formState}
                       label={t('app.shared.user_profile_form.organization_name')} />
            <FormInput id="invoicing_profile_attributes.organization_attributes.address_attributes.id"
                       register={register}
                       type="hidden" />
            <FormInput id="invoicing_profile_attributes.organization_attributes.address_attributes.address"
                       register={register}
                       rules={{ required: isOrganization }}
                       formState={formState}
                       label={t('app.shared.user_profile_form.organization_address')} />
          </div>}
        </div>
      </div>
    </form>
  );
};

UserProfileForm.defaultProps = {
  size: 'large'
};

const UserProfileFormWrapper: React.FC<UserProfileFormProps> = (props) => {
  return (
    <Loader>
      <UserProfileForm {...props} />
    </Loader>
  );
};

Application.Components.component('userProfileForm', react2angular(UserProfileFormWrapper, ['action', 'size', 'user', 'className', 'onError']));
