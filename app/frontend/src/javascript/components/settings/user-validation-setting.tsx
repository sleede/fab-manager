import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { SettingName } from '../../models/setting';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import SettingAPI from '../../api/setting';
import { Loader } from '../base/loader';
import { FabButton } from '../base/fab-button';
import { BooleanSetting } from './boolean-setting';
import { CheckListSetting } from './check-list-setting';

declare const Application: IApplication;

interface UserValidationSettingProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component allows to configure user validation required setting.
 */
const UserValidationSetting: React.FC<UserValidationSettingProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [userValidationRequired, setUserValidationRequired] = useState<string>('false');
  const userValidationRequiredListDefault = ['subscription', 'machine', 'event', 'space', 'training', 'pack'];
  const [userValidationRequiredList, setUserValidationRequiredList] = useState<string>(null);
  const userValidationRequiredOptions = userValidationRequiredListDefault.map(l => {
    return [l, t(`app.admin.settings.compte.user_validation_required_list.${l}`)];
  });

  /**
   * Save the built string to the Setting API
   */
  const updateSetting = (name: SettingName, value: string) => {
    SettingAPI.update(name, value)
      .then(() => {
        if (name === SettingName.UserValidationRequired) {
          onSuccess(t('app.admin.settings.customization_of_SETTING_successfully_saved', { SETTING: t(`app.admin.settings.compte.${name}`) }));
        }
      }).catch(err => {
        if (err.status === 304) return;

        if (err.status === 423) {
          if (name === SettingName.UserValidationRequired) {
            onError(t('app.admin.settings.error_SETTING_locked', { SETTING: t(`app.admin.settings.compte.${name}`) }));
          }
          return;
        }

        console.log(err);
        onError(t('app.admin.settings.an_error_occurred_saving_the_setting'));
      });
  };

  /**
   * Callback triggered when the 'save' button is clicked.
   */
  const handleSave = () => {
    updateSetting(SettingName.UserValidationRequired, userValidationRequired);
    if (userValidationRequiredList !== null) {
      if (userValidationRequired === 'true') {
        updateSetting(SettingName.UserValidationRequiredList, userValidationRequiredList);
      } else {
        updateSetting(SettingName.UserValidationRequiredList, null);
      }
    }
  };

  return (
    <div className="user-validation-setting">
      <BooleanSetting name={SettingName.UserValidationRequired}
        label={t('app.admin.settings.compte.user_validation_required_option_label')}
        hideSave={true}
        onChange={setUserValidationRequired}
        onSuccess={onSuccess}
        onError={onError}>
      </BooleanSetting>
      {userValidationRequired === 'true' &&
        <div>
          <h4>{t('app.admin.settings.compte.user_validation_required_list_title')}</h4>
          <p>
            {t('app.admin.settings.compte.user_validation_required_list_info')}
          </p>
          <p className="alert alert-warning">
            {t('app.admin.settings.compte.user_validation_required_list_other_info')}
          </p>
          <CheckListSetting name={SettingName.UserValidationRequiredList}
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
      <FabButton className="btn btn-warning m-t" onClick={handleSave}>{t('app.admin.check_list_setting.save')}</FabButton>
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
