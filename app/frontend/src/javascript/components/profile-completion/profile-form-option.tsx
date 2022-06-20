import React from 'react';
import { User } from '../../models/user';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ActiveProviderResponse } from '../../models/authentication-provider';
import { useTranslation } from 'react-i18next';
import { HtmlTranslate } from '../base/html-translate';
import { UserProfileForm } from '../user/user-profile-form';
import UserLib from '../../lib/user';
import { FabButton } from '../base/fab-button';
import Authentication from '../../api/authentication';

declare const Application: IApplication;

interface ProfileFormOptionProps {
  user: User,
  activeProvider: ActiveProviderResponse,
  onError: (message: string) => void,
  onSuccess: (user: User) => void,
}

/**
 * After first logged-in from a SSO, the user has two options:
 * - complete his profile (*) ;
 * - bind his profile to his existing account ;
 * (*) This component handle the first case.
 * It also deals with duplicate email addresses in database
 */
export const ProfileFormOption: React.FC<ProfileFormOptionProps> = ({ user, activeProvider, onError, onSuccess }) => {
  const { t } = useTranslation('logged');

  const userLib = new UserLib(user);

  /**
   * Route the current user to the interface provided by the authentication provider, to update his profile.
   */
  const redirectToSsoProfile = (): void => {
    window.open(activeProvider.link_to_sso_profile, '_blank');
  };

  /**
   * Disconnect and re-connect the user to the SSO to force the synchronisation of the profile's data
   */
  function syncProfile () {
    Authentication.logout().then(() => {
      window.location.href = activeProvider.link_to_sso_connect;
    }).catch(onError);
  }

  return (
    <div className="profile-form-option">
      <h3>{t('app.logged.profile_completion.profile_form_option.title')}</h3>
      {!userLib.hasDuplicate() && <div className="normal-flow">
        <p>{t('app.logged.profile_completion.profile_form_option.please_fill')}</p>
        <p className="disabled-fields-info">{t('app.logged.profile_completion.profile_form_option.disabled_data_from_sso', { NAME: activeProvider?.name })}</p>
        <p className="confirm-instructions">
          <HtmlTranslate trKey="app.logged.profile_completion.profile_form_option.confirm_instructions_html" />
        </p>
        <UserProfileForm onError={onError}
                         action="update"
                         user={user}
                         onSuccess={onSuccess}
                         size="small"
                         showGroupInput
                         showTermsAndConditionsInput />
      </div>}
      {userLib.hasDuplicate() && <div className="duplicate-email">
        <p className="duplicate-info">
          <HtmlTranslate trKey="app.logged.profile_completion.profile_form_option.duplicate_email_html"
                         options={{ EMAIL: userLib.ssoEmail(), PROVIDER: activeProvider?.name }} />
        </p>
        <FabButton onClick={redirectToSsoProfile} icon={<i className="fa fa-edit"/>}>
          {t('app.logged.profile_completion.profile_form_option.edit_profile')}
        </FabButton>
        <p className="after-edition-info">
          <HtmlTranslate trKey="app.logged.profile_completion.profile_form_option.after_edition_info_html" />
        </p>
        <FabButton onClick={syncProfile} icon={<i className="fa fa-refresh"/>}>
          {t('app.logged.profile_completion.profile_form_option.sync_profile')}
        </FabButton>
      </div>}
    </div>
  );
};

const ProfileFormOptionWrapper: React.FC<ProfileFormOptionProps> = (props) => {
  return (
    <Loader>
      <ProfileFormOption {...props} />
    </Loader>
  );
};

Application.Components.component('profileFormOption', react2angular(ProfileFormOptionWrapper, ['user', 'activeProvider', 'onError', 'onSuccess']));
