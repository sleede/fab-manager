import React from 'react';
import { react2angular } from 'react2angular';
import { SubmitHandler, useForm, useWatch } from 'react-hook-form';
import { isNil as _isNil } from 'lodash';
import { User } from '../../models/user';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { FormInput } from '../form/form-input';
import { useTranslation } from 'react-i18next';
import { Avatar } from './avatar';
import { GenderInput } from './gender-input';
import { ChangePassword } from './change-password';
import { PasswordInput } from './password-input';
import { FormSwitch } from '../form/form-switch';
import { FormRichText } from '../form/form-rich-text';
import MemberAPI from '../../api/member';

declare const Application: IApplication;

interface UserProfileFormProps {
  action: 'create' | 'update',
  size?: 'small' | 'large',
  user: User,
  className?: string,
  onError: (message: string) => void,
  onSuccess: (user: User) => void,
}

export const UserProfileForm: React.FC<UserProfileFormProps> = ({ action, size, user, className, onError, onSuccess }) => {
  const { t } = useTranslation('shared');

  // regular expression to validate the the input fields
  const phoneRegex = /^((00|\+)[0-9]{2,3})?[0-9]{4,14}$/;
  const urlRegex = /^(https?:\/\/)([\da-z.-]+)\.([-a-z0-9.]{2,30})([/\w .-]*)*\/?$/;

  const { handleSubmit, register, control, formState } = useForm<User>({ defaultValues: { ...user } });
  const output = useWatch<User>({ control });

  const [isOrganization, setIsOrganization] = React.useState<boolean>(!_isNil(user.invoicing_profile_attributes.organization_attributes));

  /**
   * Callback triggered when the form is submitted: process with the user creation or update.
   */
  const onSubmit: SubmitHandler<User> = (data: User) => {
    MemberAPI[action](data)
      .then(res => { onSuccess(res); })
      .catch((error) => { onError(error); });
  };

  return (
    <form className={`user-profile-form user-profile-form--${size} ${className}`} onSubmit={handleSubmit(onSubmit)}>
      <div className="avatar-group">
        <Avatar user={user} />
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
                           value: phoneRegex,
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
          <FormSwitch control={control}
                      id="invoicing_profile_attributes.organization"
                      label={t('app.shared.user_profile_form.declare_organization')}
                      tooltip={t('app.shared.user_profile_form.declare_organization_help')}
                      defaultValue={isOrganization}
                      onChange={setIsOrganization} />
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
        <div className="profile-data">
          <h4>{t('app.shared.user_profile_form.profile_data')}</h4>
          <div className="website-job">
            <FormInput id="profile_attributes.website"
                       register={register}
                       rules={{
                         pattern: {
                           value: urlRegex,
                           message: t('app.shared.user_profile_form.website_invalid')
                         }
                       }}
                       placeholder="https://www.example.com"
                       formState={formState}
                       label={t('app.shared.user_profile_form.website')} />
            <FormInput id="profile_attributes.job"
                       register={register}
                       label={t('app.shared.user_profile_form.job')} />
          </div>
          <div className="interests-CAD">
            <FormRichText control={control}
                          id="profile_attributes.interest"
                          label={t('app.shared.user_profile_form.interests')} />
            <FormRichText control={control}
                          id="profile_attributes.software_mastered"
                          label={t('app.shared.user_profile_form.CAD_softwares_mastered')} />
          </div>
        </div>
        <div className="preferences-data">
          <h4>{t('app.shared.user_profile_form.preferences_data')}</h4>
          <FormSwitch control={control}
                      id="is_allow_contact"
                      label={t('app.shared.user_profile_form.allow_public_profile')}
                      tooltip={t('app.shared.user_profile_form.allow_public_profile_help')} />
          <FormSwitch control={control}
                      id="is_allow_newsletter"
                      label={t('app.shared.user_profile_form.allow_newsletter')}
                      tooltip={t('app.shared.user_profile_form.allow_newsletter_help')} />
        </div>
        <div>
          <button type="submit">GO</button>
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

Application.Components.component('userProfileForm', react2angular(UserProfileFormWrapper, ['action', 'size', 'user', 'className', 'onError', 'onSuccess']));
