import React, { useEffect, useState } from 'react';
import Switch from 'react-switch';
import _ from 'lodash';
import { AxiosResponse } from 'axios';
import { useTranslation } from 'react-i18next';
import { SettingName } from '../../models/setting';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import SettingAPI from '../../api/setting';
import { Loader } from '../base/loader';
import { FabButton } from '../base/fab-button';

declare const Application: IApplication;

interface BooleanSettingProps {
  name: SettingName,
  label: string,
  className?: string,
  hideSave?: boolean,
  onChange?: (value: string) => void,
  onBeforeSave?: (message: string) => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component allows to configure boolean value for a setting.
 */
export const BooleanSetting: React.FC<BooleanSettingProps> = ({ name, label, className, hideSave, onChange, onSuccess, onError, onBeforeSave }) => {
  const { t } = useTranslation('admin');

  const [value, setValue] = useState<boolean>(false);

  // on component load, we retrieve the current value of the list from the API
  useEffect(() => {
    SettingAPI.get(name)
      .then(res => {
        setValue(res.value === 'true');
        if (_.isFunction(onChange)) {
          onChange(res.value === 'true' ? 'true' : 'false');
        }
      })
      .catch(err => onError(err));
  }, []);

  /**
   * Save the built string to the Setting API
   */
  const updateSetting = () => {
    SettingAPI.update(name, value ? 'true' : 'false')
      .then(() => onSuccess(t('app.admin.settings.customization_of_SETTING_successfully_saved', { SETTING: t(`app.admin.settings.${name}`) })))
      .catch(err => {
        if (err.status === 304) return;

        if (err.status === 423) {
          onError(t('app.admin.settings.error_SETTING_locked', { SETTING: t(`app.admin.settings.${name}`) }));
          return;
        }

        console.log(err);
        onError(t('app.admin.settings.an_error_occurred_saving_the_setting'));
      });
  };

  /**
   * Callback triggered when the 'save' button is clicked.
   * Save the built string to the Setting API
   */
  const handleSave = () => {
    if (_.isFunction(onBeforeSave)) {
      const res = onBeforeSave({ value, name });
      if (res && _.isFunction(res.then)) {
        // res is a promise, wait for it before proceed
        res.then((success: AxiosResponse) => {
          if (success) updateSetting();
          else setValue(false);
        }, function () {
          setValue(false);
        });
      } else {
        if (res) updateSetting();
        else setValue(false);
      }
    } else {
      updateSetting();
    }
  };

  /**
   * Callback triggered when the 'switch' is changed.
   */
  const handleChanged = (_value: boolean) => {
    setValue(_value);
    if (_.isFunction(onChange)) {
      onChange(_value ? 'true' : 'false');
    }
  };

  return (
    <div className={`form-group ${className || ''}`}>
      <label htmlFor={`setting-${name}`} className="control-label m-r">{label}</label>
      <Switch checked={value} id={`setting-${name}}`} onChange={handleChanged} className="v-middle"></Switch>
      {!hideSave && <FabButton className="btn btn-warning m-l" onClick={handleSave}>{t('app.admin.check_list_setting.save')}</FabButton> }
    </div>
  );
};

export const BooleanSettingWrapper: React.FC<BooleanSettingProps> = ({ onChange, onSuccess, onError, label, className, name, hideSave, onBeforeSave }) => {
  return (
    <Loader>
      <BooleanSetting label={label} name={name} onError={onError} onSuccess={onSuccess} onChange={onChange} className={className} hideSave={hideSave} onBeforeSave={onBeforeSave} />
    </Loader>
  );
};

Application.Components.component('booleanSetting', react2angular(BooleanSettingWrapper, ['className', 'name', 'label', 'onChange', 'onSuccess', 'onError', 'onBeforeSave']));
