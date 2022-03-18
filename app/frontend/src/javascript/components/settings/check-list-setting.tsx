import React, { BaseSyntheticEvent, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import _ from 'lodash';
import { SettingName } from '../../models/setting';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import SettingAPI from '../../api/setting';
import { Loader } from '../base/loader';
import { FabButton } from '../base/fab-button';

declare const Application: IApplication;

interface CheckListSettingProps {
  name: SettingName,
  label: string,
  className?: string,
  hideSave?: boolean,
  defaultValue?: string,
  // availableOptions must be like this [['option1', 'label 1'], ['option2', 'label 2']]
  availableOptions: Array<Array<string>>,
  onChange?: (value: string) => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component allows to configure multiples values for a setting, like a check list.
 * The result is stored as a string, composed of the checked values, e.g. 'option1,option2'
 */
export const CheckListSetting: React.FC<CheckListSettingProps> = ({ name, label, hideSave, defaultValue, className, availableOptions, onChange, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [value, setValue] = useState<string>(null);

  // on component load, we retrieve the current value of the list from the API
  useEffect(() => {
    SettingAPI.get(name)
      .then(res => {
        const value = res.value === null && defaultValue ? defaultValue : res.value;
        setValue(value);
        if (_.isFunction(onChange)) {
          onChange(value);
        }
      })
      .catch(err => onError(err));
  }, []);

  /**
   * Callback triggered when a checkbox is ticked or unticked.
   * This function construct the resulting string, by adding or deleting the provided option identifier.
   */
  const toggleCheckbox = (option: string) => {
    return (event: BaseSyntheticEvent) => {
      if (event.target.checked) {
        let newValue = value ? `${value},` : '';
        newValue += option;
        setValue(newValue);
        if (_.isFunction(onChange)) {
          onChange(newValue);
        }
      } else {
        const regex = new RegExp(`,?${option}`, 'g');
        const newValue = value.replace(regex, '');
        setValue(newValue);
        if (_.isFunction(onChange)) {
          onChange(newValue);
        }
      }
    };
  };

  /**
   * Callback triggered when the 'save' button is clicked.
   * Save the built string to the Setting API
   */
  const handleSave = () => {
    SettingAPI.update(name, value)
      .then(() => onSuccess(t('app.admin.check_list_setting.customization_of_SETTING_successfully_saved', { SETTING: t(`app.admin.settings.${name}`) })))
      .catch(err => onError(err));
  };

  /**
   * Verify if the provided option is currently ticked (i.e. included in the value string)
   */
  const isChecked = (option) => {
    return value?.includes(option);
  };

  return (
    <div className={`check-list-setting ${className || ''}`}>
      <h4 className="check-list-title">{label}</h4>
      {availableOptions.map(option => <div key={option[0]}>
        <input id={`setting-${name}-${option[0]}`} type="checkbox" checked={isChecked(option[0])} onChange={toggleCheckbox(option[0])} />
        <label htmlFor={`setting-${name}-${option[0]}`}>{option[1]}</label>
      </div>)}
      {!hideSave && <FabButton className="save" onClick={handleSave}>{t('app.admin.check_list_setting.save')}</FabButton>}
    </div>
  );
};

export const CheckListSettingWrapper: React.FC<CheckListSettingProps> = ({ availableOptions, onSuccess, onError, label, className, name, hideSave, defaultValue, onChange }) => {
  return (
    <Loader>
      <CheckListSetting availableOptions={availableOptions} label={label} name={name} onError={onError} onSuccess={onSuccess} className={className} hideSave={hideSave} defaultValue={defaultValue} onChange={onChange} />
    </Loader>
  );
};

Application.Components.component('checkListSetting', react2angular(CheckListSettingWrapper, ['className', 'name', 'label', 'availableOptions', 'onSuccess', 'onError']));
