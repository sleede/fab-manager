import { useState } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { SettingName } from '../../models/setting';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import SettingAPI from '../../api/setting';
import { Loader } from '../base/loader';
import { FabButton } from '../base/fab-button';
import { BooleanSetting } from './boolean-setting';
import { CheckListSetting } from './check-list-setting';
import { FabAlert } from '../base/fab-alert';

declare const Application: IApplication;

interface UserValidationSettingProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component allows an admin to configure the settings related to the user account validation.
 */
export const UserValidationSetting: React.FC<UserValidationSettingProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [userValidationRequired, setUserValidationRequired] = useState<string>('false');
  const userValidationRequiredListDefault = ['subscription', 'machine', 'event', 'space', 'training', 'pack'];
  const [userValidationRequiredList, setUserValidationRequiredList] = useState<string>(null);
  const userValidationRequiredOptions = userValidationRequiredListDefault.map(l => {
    return [l, t(`app.admin.settings.account.user_validation_setting.user_validation_required_list.${l}`)];
  });

  /**
   * Save the built string to the Setting API
   */
  const updateSetting = (name: SettingName, value: string) => {
    SettingAPI.update(name, value)
      .then(() => {
        if (name === 'user_validation_required') {
          onSuccess(t('app.admin.settings.account.user_validation_setting.customization_of_SETTING_successfully_saved', {
            SETTING: t(`app.admin.settings.account.${name}`) // eslint-disable-line fabmanager/scoped-translation
          }));
        }
      }).catch(err => {
        if (err.status === 304) return;

        if (err.status === 423) {
          if (name === 'user_validation_required') {
            onError(t('app.admin.settings.account.user_validation_setting.error_SETTING_locked', {
              SETTING: t(`app.admin.settings.account.${name}`) // eslint-disable-line fabmanager/scoped-translation
            }));
          }
          return;
        }

        console.log(err);
        onError(t('app.admin.settings.account.user_validation_setting.an_error_occurred_saving_the_setting'));
      });
  };

  /**
   * Callback triggered when the 'save' button is clicked.
   */
  const handleSave = () => {
    updateSetting('user_validation_required', userValidationRequired);
    if (userValidationRequiredList !== null) {
      if (userValidationRequired === 'true') {
        updateSetting('user_validation_required_list', userValidationRequiredList);
      } else {
        updateSetting('user_validation_required_list', null);
      }
    }
  };

  return (
    <div className="user-validation-setting">
      <BooleanSetting name={'user_validation_required'}
        label={t('app.admin.settings.account.user_validation_setting.user_validation_required_option_label')}
        hideSave={true}
        onChange={setUserValidationRequired}
        onSuccess={onSuccess}
        onError={onError}>
      </BooleanSetting>
      {userValidationRequired === 'true' &&
        <div>
          <h4>{t('app.admin.settings.account.user_validation_setting.user_validation_required_list_title')}</h4>
          <p>
            {t('app.admin.settings.account.user_validation_setting.user_validation_required_list_info')}
          </p>
          <FabAlert level="warning">
            {t('app.admin.settings.account.user_validation_setting.user_validation_required_list_other_info')}
          </FabAlert>
          <CheckListSetting name={'user_validation_required_list'}
            label=""
            availableOptions={userValidationRequiredOptions}
            defaultValue={userValidationRequiredListDefault.join(',')}
            hideSave={true}
            onChange={setUserValidationRequiredList}
            onSuccess={onSuccess}
            onError={onError}>
          </CheckListSetting>
        </div>
      }
      <FabButton className="save-btn" onClick={handleSave}>{t('app.admin.settings.account.user_validation_setting.save')}</FabButton>
    </div>
  );
};

const UserValidationSettingWrapper: React.FC<UserValidationSettingProps> = ({ onSuccess, onError }) => {
  return (
    <Loader>
      <UserValidationSetting onError={onError} onSuccess={onSuccess} />
    </Loader>
  );
};

Application.Components.component('userValidationSetting', react2angular(UserValidationSettingWrapper, ['onSuccess', 'onError']));
