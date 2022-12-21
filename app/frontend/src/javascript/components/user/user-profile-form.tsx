import { useEffect, useState } from 'react';
import * as React from 'react';
import { react2angular } from 'react2angular';
import { useForm, useWatch, ValidateResult } from 'react-hook-form';
import { isNil as _isNil } from 'lodash';
import { User, UserFieldMapping, UserFieldsReservedForPrivileged } from '../../models/user';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { FormInput } from '../form/form-input';
import { useTranslation } from 'react-i18next';
import { GenderInput } from './gender-input';
import { ChangePassword } from './change-password';
import { PasswordInput } from './password-input';
import { FormSwitch } from '../form/form-switch';
import { FormRichText } from '../form/form-rich-text';
import MemberAPI from '../../api/member';
import { AvatarInput } from './avatar-input';
import { FabButton } from '../base/fab-button';
import { EditSocials } from '../socials/edit-socials';
import UserLib from '../../lib/user';
import AuthProviderAPI from '../../api/auth-provider';
import { FormSelect } from '../form/form-select';
import GroupAPI from '../../api/group';
import CustomAssetAPI from '../../api/custom-asset';
import { CustomAsset, CustomAssetName } from '../../models/custom-asset';
import { HtmlTranslate } from '../base/html-translate';
import TrainingAPI from '../../api/training';
import TagAPI from '../../api/tag';
import { FormMultiSelect } from '../form/form-multi-select';
import ProfileCustomFieldAPI from '../../api/profile-custom-field';
import { ProfileCustomField } from '../../models/profile-custom-field';
import { SettingName } from '../../models/setting';
import SettingAPI from '../../api/setting';
import { SelectOption } from '../../models/select';

declare const Application: IApplication;

interface UserProfileFormProps {
  action: 'create' | 'update',
  size?: 'small' | 'large',
  user: User,
  operator: User,
  className?: string,
  onError: (message: string) => void,
  onSuccess: (user: User) => void,
  showGroupInput?: boolean,
  showTermsAndConditionsInput?: boolean,
  showTrainingsInput?: boolean,
  showTagsInput?: boolean,
}

/**
 * Form component to create or update a user
 */
export const UserProfileForm: React.FC<UserProfileFormProps> = ({ action, size, user, operator, className, onError, onSuccess, showGroupInput, showTermsAndConditionsInput, showTrainingsInput, showTagsInput }) => {
  const { t } = useTranslation('shared');

  // regular expression to validate the input fields
  const phoneRegex = /^((00|\+)\d{2,3})?[\d -]{4,14}$/;
  const urlRegex = /^(https?:\/\/)([^.]+)\.(.{2,30})(\/.*)*\/?$/;

  const { handleSubmit, register, control, formState, setValue, reset } = useForm<User>({ defaultValues: { ...user } });
  const output = useWatch<User>({ control });

  const [isOrganization, setIsOrganization] = useState<boolean>(!_isNil(user.invoicing_profile_attributes.organization_attributes));
  const [isLocalDatabaseProvider, setIsLocalDatabaseProvider] = useState<boolean>(false);
  const [groups, setGroups] = useState<SelectOption<number>[]>([]);
  const [termsAndConditions, setTermsAndConditions] = useState<CustomAsset>(null);
  const [profileCustomFields, setProfileCustomFields] = useState<ProfileCustomField[]>([]);
  const [fieldsSettings, setFieldsSettings] = useState<Map<SettingName, string>>(new Map());

  useEffect(() => {
    AuthProviderAPI.active().then(data => {
      setIsLocalDatabaseProvider(data.providable_type === 'DatabaseProvider');
    }).catch(error => onError(error));
    if (showGroupInput) {
      GroupAPI.index({ disabled: false }).then(data => {
        setGroups(buildOptions(data));
      }).catch(error => onError(error));
    }
    if (showTermsAndConditionsInput) {
      CustomAssetAPI.get(CustomAssetName.CguFile).then(cgu => {
        if (cgu?.custom_asset_file_attributes) setTermsAndConditions(cgu);
      }).catch(error => onError(error));
    }
    ProfileCustomFieldAPI.index({ actived: true }).then(data => {
      setProfileCustomFields(data);
      const userProfileCustomFields = data.map(f => {
        const upcf = user?.invoicing_profile_attributes?.user_profile_custom_fields_attributes?.find(uf => uf.profile_custom_field_id === f.id);
        return upcf || {
          value: '',
          invoicing_profile_id: user.invoicing_profile_attributes.id,
          profile_custom_field_id: f.id
        };
      });
      setValue('invoicing_profile_attributes.user_profile_custom_fields_attributes', userProfileCustomFields);
    }).catch(error => onError(error));
    SettingAPI.query(['phone_required', 'address_required', 'external_id'])
      .then(settings => setFieldsSettings(settings))
      .catch(error => onError(error));
  }, []);

  /**
   * Convert the provided array of items to the react-select format
   */
  const buildOptions = (items: Array<{ id?: number, name: string }>): Array<SelectOption<number>> => {
    return items.map(t => {
      return { value: t.id, label: t.name };
    });
  };

  /**
   * Asynchronously load the full list of enabled trainings to display in the drop-down select field
   */
  const loadTrainings = (inputValue: string, callback: (options: Array<SelectOption<number>>) => void): void => {
    TrainingAPI.index({ disabled: false }).then(data => {
      callback(buildOptions(data));
    }).catch(error => onError(error));
  };

  /**
   * Asynchronously load the full list of tags to display in the drop-down select field
   */
  const loadTags = (inputValue: string, callback: (options: Array<SelectOption<number>>) => void): void => {
    TagAPI.index().then(data => {
      callback(buildOptions(data));
    }).catch(error => onError(error));
  };

  /**
   * Callback triggered when the form is submitted: process with the user creation or update.
   */
  const onSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    if (showTermsAndConditionsInput) {
      // When the form is submitted, we consider that the user should have accepted the terms and conditions,
      // so we mark the field as dirty, even if he doesn't touch it. Like that, the error message is displayed.
      setValue('cgu', !!output.cgu, { shouldDirty: true, shouldTouch: true });
    }

    return handleSubmit((data: User) => {
      MemberAPI[action](data)
        .then(res => {
          reset(res);
          onSuccess(res);
        })
        .catch((error) => { onError(error); });
    })(event);
  };

  /**
   * Check if the given field path should be disabled
   */
  const isDisabled = function (id: string) {
    // some fields may be reserved in edition for priviledged users
    if (UserFieldsReservedForPrivileged.includes(id) && !(new UserLib(operator).isPrivileged(user))) {
      return true;
    }
    // if the current provider is the local database, then all fields are enabled
    if (isLocalDatabaseProvider) {
      return false;
    }

    // if the current provider is not the local database, then fields are disabled based on their mapping status.
    return user.mapped_from_sso?.includes(UserFieldMapping[id]);
  };

  /**
   * Check if the user has accepted the terms and conditions
   */
  const checkAcceptTerms = function (value: boolean): ValidateResult {
    return value === true || (t('app.shared.user_profile_form.must_accept_terms') as string);
  };

  const userNetworks = new UserLib(user).getUserSocialNetworks();

  return (
    <form className={`user-profile-form user-profile-form--${size} ${className || ''}`} onSubmit={onSubmit}>
      <div className="avatar-group">
        <AvatarInput currentAvatar={output.profile_attributes?.user_avatar_attributes?.attachment_url}
                     userName={`${output.profile_attributes?.first_name} ${output.profile_attributes?.last_name}`}
                     register={register}
                     setValue={setValue}
                     size={size} />
      </div>
      <div className="fields-group">
        <div className="personnal-data">
          <h4>{t('app.shared.user_profile_form.personal_data')}</h4>
          <GenderInput register={register} disabled={isDisabled} />
          <div className="names">
            <FormInput id="profile_attributes.last_name"
                       register={register}
                       rules={{ required: true }}
                       disabled={isDisabled}
                       formState={formState}
                       label={t('app.shared.user_profile_form.surname')} />
            <FormInput id="profile_attributes.first_name"
                       register={register}
                       rules={{ required: true }}
                       disabled={isDisabled}
                       formState={formState}
                       label={t('app.shared.user_profile_form.first_name')} />
          </div>
          <div className="birth-phone">
            <FormInput id="statistic_profile_attributes.birthday"
                       register={register}
                       label={t('app.shared.user_profile_form.date_of_birth')}
                       disabled={isDisabled}
                       rules={{ required: true }}
                       type="date" />
            <FormInput id="profile_attributes.phone"
                       register={register}
                       rules={{
                         pattern: {
                           value: phoneRegex,
                           message: t('app.shared.user_profile_form.phone_number_invalid')
                         },
                         required: fieldsSettings.get('phone_required') === 'true'
                       }}
                       disabled={isDisabled}
                       formState={formState}
                       label={t('app.shared.user_profile_form.phone_number')} />
          </div>
          <div className="address">
            <FormInput id="invoicing_profile_attributes.address_attributes.id"
                       register={register}
                       type="hidden" />
            <FormInput id="invoicing_profile_attributes.address_attributes.address"
                       register={register}
                       disabled={isDisabled}
                       rules={{ required: fieldsSettings.get('address_required') === 'true' }}
                       label={t('app.shared.user_profile_form.address')} />
          </div>
        </div>
        <div className="account-data">
          <h4>{t('app.shared.user_profile_form.account_data')}</h4>
          <FormInput id="username"
                     register={register}
                     rules={{ required: true }}
                     disabled={isDisabled}
                     formState={formState}
                     label={t('app.shared.user_profile_form.pseudonym')} />
          {fieldsSettings.get('external_id') === 'true' && <FormInput id="invoicing_profile_attributes.external_id"
                     register={register}
                     disabled={isDisabled}
                     formState={formState}
                     label={t('app.shared.user_profile_form.external_id')} />}
          <FormInput id="email"
                     register={register}
                     rules={{ required: true }}
                     disabled={isDisabled}
                     formState={formState}
                     label={t('app.shared.user_profile_form.email_address')} />
          {isLocalDatabaseProvider && <div className="password">
            { action === 'update' && <ChangePassword register={register}
                                                     onError={onError}
                                                     currentFormPassword={output.password}
                                                     user={user}
                                                     formState={formState}
                                                     setValue={setValue} />}
            {action === 'create' && <PasswordInput register={register}
              currentFormPassword={output.password}
              formState={formState} />}
          </div>}
        </div>
        <div className="organization-data">
          <h4>{t('app.shared.user_profile_form.organization_data')}</h4>
          <FormSwitch control={control}
                      id="invoicing_profile_attributes.organization"
                      label={t('app.shared.user_profile_form.declare_organization')}
                      tooltip={t('app.shared.user_profile_form.declare_organization_help')}
                      defaultValue={isOrganization}
                      disabled={isDisabled('invoicing_profile_attributes.organization_attributes.name')}
                      onChange={setIsOrganization} />
          {isOrganization && <div className="organization-fields">
            <FormInput id="invoicing_profile_attributes.organization_attributes.id"
                       register={register}
                       type="hidden" />
            <FormInput id="invoicing_profile_attributes.organization_attributes.name"
                       register={register}
                       rules={{ required: isOrganization }}
                       disabled={isDisabled}
                       formState={formState}
                       label={t('app.shared.user_profile_form.organization_name')} />
            <FormInput id="invoicing_profile_attributes.organization_attributes.address_attributes.id"
                       register={register}
                       type="hidden" />
            <FormInput id="invoicing_profile_attributes.organization_attributes.address_attributes.address"
                       register={register}
                       rules={{ required: isOrganization }}
                       disabled={isDisabled}
                       formState={formState}
                       label={t('app.shared.user_profile_form.organization_address')} />
            {profileCustomFields.map((f, i) => {
              return (<FormInput key={`profileCustomField${i}`}
                           id={`invoicing_profile_attributes.user_profile_custom_fields_attributes[${i}].value`}
                           register={register}
                           rules={{ required: f.required ? t('app.shared.user_profile_form.profile_custom_field_is_required', { FEILD: f.label }) as string : false }}
                           disabled={isDisabled}
                           formState={formState}
                           label={f.label} />);
            })}
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
                       disabled={isDisabled}
                       formState={formState}
                       label={t('app.shared.user_profile_form.website')} />
            <FormInput id="profile_attributes.job"
                       register={register}
                       label={t('app.shared.user_profile_form.job')} />
          </div>
          <div className="interests-CAD">
            <FormRichText control={control}
                          id="profile_attributes.interest"
                          disabled={isDisabled}
                          label={t('app.shared.user_profile_form.interests')} />
            <FormRichText control={control}
                          disabled={isDisabled}
                          id="profile_attributes.software_mastered"
                          label={t('app.shared.user_profile_form.CAD_softwares_mastered')} />
          </div>
        </div>
        <div className='account-networks'>
          <h4>{t('app.shared.user_profile_form.account_networks')}</h4>
          <EditSocials register={register}
                       disabled={isDisabled}
                       networks={userNetworks}
                       setValue={setValue}
                       formState={formState} />
        </div>
        <div className="preferences-data">
          <h4>{t('app.shared.user_profile_form.preferences_data')}</h4>
          <FormSwitch control={control}
                      id="is_allow_contact"
                      disabled={isDisabled}
                      label={t('app.shared.user_profile_form.allow_public_profile')}
                      tooltip={t('app.shared.user_profile_form.allow_public_profile_help')} />
          <FormSwitch control={control}
                      id="is_allow_newsletter"
                      disabled={isDisabled}
                      label={t('app.shared.user_profile_form.allow_newsletter')}
                      tooltip={t('app.shared.user_profile_form.allow_newsletter_help')} />
        </div>
        {showGroupInput && <div className="group">
          <FormSelect options={groups}
                      control={control}
                      id="group_id"
                      rules={{ required: true }}
                      disabled={isDisabled}
                      formState={formState}
                      label={t('app.shared.user_profile_form.group')} />
        </div>}
        {showTrainingsInput && <div className="trainings">
          <FormMultiSelect control={control}
                           loadOptions={loadTrainings}
                           formState={formState}
                           label={t('app.shared.user_profile_form.trainings')}
                           id="statistic_profile_attributes.training_ids" />
        </div>}
        {showTagsInput && <div className="tags">
          <FormMultiSelect control={control}
                           loadOptions={loadTags}
                           formState={formState}
                           label={t('app.shared.user_profile_form.tags')}
                           id="tag_ids" />
        </div>}
        {new UserLib(operator).isPrivileged(user) && <div className="note">
          <FormRichText control={control}
                        label={t('app.shared.user_profile_form.note')}
                        tooltip={t('app.shared.user_profile_form.note_help')}
                        limit={null}
                        id="profile_attributes.note" />
        </div>}
        {showTermsAndConditionsInput && termsAndConditions && <div className="terms-and-conditions">
          <FormSwitch control={control}
                      disabled={isDisabled}
                      id="cgu"
                      rules={{ validate: checkAcceptTerms }}
                      formState={formState}
                      label={<HtmlTranslate trKey="app.shared.user_profile_form.terms_and_conditions_html"
                                            options={{ POLICY_URL: termsAndConditions.custom_asset_file_attributes.attachment_url }} />}
          />
        </div>}
        <div className="main-actions">
          <FabButton type="submit" className="submit-button">{t('app.shared.user_profile_form.save')}</FabButton>
        </div>
      </div>
    </form>
  );
};

UserProfileForm.defaultProps = {
  size: 'large',
  showGroupInput: false,
  showTrainingsInput: false,
  showTermsAndConditionsInput: false,
  showTagsInput: false
};

const UserProfileFormWrapper: React.FC<UserProfileFormProps> = (props) => {
  return (
    <Loader>
      <UserProfileForm {...props} />
    </Loader>
  );
};

Application.Components.component('userProfileForm', react2angular(UserProfileFormWrapper, ['action', 'size', 'user', 'operator', 'className', 'onError', 'onSuccess', 'showGroupInput', 'showTermsAndConditionsInput', 'showTagsInput', 'showTrainingsInput']));
