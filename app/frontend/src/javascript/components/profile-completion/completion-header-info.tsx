import React, { useEffect } from 'react';
import { ActiveProviderResponse } from '../../models/authentication-provider';
import { useTranslation } from 'react-i18next';
import { User } from '../../models/user';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';
import SettingAPI from '../../api/setting';
import { SettingName } from '../../models/setting';
import UserLib from '../../lib/user';

declare const Application: IApplication;

interface CompletionHeaderInfoProps {
  user: User,
  activeProvider: ActiveProviderResponse,
  onError: (message: string) => void,
}

/**
 * This component will show an information message, on the profile completion page.
 */
export const CompletionHeaderInfo: React.FC<CompletionHeaderInfoProps> = ({ user, activeProvider, onError }) => {
  const { t } = useTranslation('logged');
  const [settings, setSettings] = React.useState<Map<SettingName, string>>(null);

  const userLib = new UserLib(user);

  useEffect(() => {
    SettingAPI.query([SettingName.NameGenre, SettingName.FablabName]).then(setSettings).catch(onError);
  }, []);

  return (
    <div className="completion-header-info">
      {activeProvider?.providable_type === 'DatabaseProvider' && <div className="header-info--local-database">
        <p>{t('app.logged.profile_completion.completion_header_info.rules_changed')}</p>
      </div>}
      {activeProvider?.providable_type !== 'DatabaseProvider' && <div className="header-info--sso">
        <p className="intro">
          <span>
            {t('app.logged.profile_completion.completion_header_info.sso_intro', {
              GENDER: settings?.get(SettingName.NameGenre),
              NAME: settings?.get(SettingName.FablabName)
            })}
          </span>
          <span className="provider-name">
            {activeProvider?.name}
            {userLib.ssoEmail() && <span className="user-email">({ userLib.ssoEmail() })</span>}
          </span>
        </p>
        {userLib.hasDuplicate() && <p className="duplicate-email-info">
          {t('app.logged.profile_completion.completion_header_info.duplicate_email_info')}
        </p>}
        {!userLib.hasDuplicate() && <p className="details-needed-info">
          {t('app.logged.profile_completion.completion_header_info.details_needed_info')}
        </p>}
      </div>}
    </div>
  );
};

const CompletionHeaderInfoWrapper: React.FC<CompletionHeaderInfoProps> = (props) => {
  return (
    <Loader>
      <CompletionHeaderInfo {...props} />
    </Loader>
  );
};

Application.Components.component('completionHeaderInfo', react2angular(CompletionHeaderInfoWrapper, ['user', 'activeProvider', 'onError']));
