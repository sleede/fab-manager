import React, { BaseSyntheticEvent, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { SettingName } from '../../models/setting';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import SettingAPI from '../../api/setting';
import { Loader } from '../base/loader';

declare const Application: IApplication;

interface CheckListSettingProps {
  name: SettingName,
  label: string,
  className?: string,
  allSettings: Record<SettingName, string>,
  availableOptions: Array<string>,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

const CheckListSetting: React.FC<CheckListSettingProps> = ({ name, label, className, allSettings, availableOptions, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [value, setValue] = useState<string>(null);

  useEffect(() => {
    if (!allSettings) return;

    setValue(allSettings[name]);
  }, [allSettings]);

  const toggleCheckbox = (option: string) => {
    return (event: BaseSyntheticEvent) => {
      if (event.target.checked) {
        let newValue = value ? `${value},` : '';
        newValue += option;
        setValue(newValue);
      } else {
        const regex = new RegExp(`,?${option}`, 'g');
        setValue(value.replace(regex, ''));
      }
    };
  };

  const handleSave = () => {
    SettingAPI.update(name, value)
      .then(() => onSuccess(t('app.admin.check_list_setting.customization_of_SETTING_successfully_saved', { SETTING: t(`app.admin.settings.${name}`) })))
      .catch(err => onError(err));
  };

  const isChecked = (option) => {
    return value?.includes(option);
  };

  return (
    <div className={`check-list-setting ${className || ''}`}>
      <span className="check-list-title">{label}</span>
      {availableOptions.map(option => <div key={option}>
        <input id={`setting-${name}-${option}`} type="checkbox" checked={isChecked(option)} onChange={toggleCheckbox(option)} />
        <label htmlFor={`setting-${name}-${option}`}>{option}</label>
      </div>)}
      <button className="save" onClick={handleSave}>{t('app.admin.buttons.save')}</button>
    </div>
  );
};

const CheckListSettingWrapper: React.FC<CheckListSettingProps> = ({ allSettings, availableOptions, onSuccess, onError, label, className, name }) => {
  return (
    <Loader>
      <CheckListSetting allSettings={allSettings} availableOptions={availableOptions} label={label} name={name} onError={onError} onSuccess={onSuccess} className={className} />
    </Loader>
  );
};

Application.Components.component('checkListSetting', react2angular(CheckListSettingWrapper, ['allSettings', 'className', 'name', 'label', 'availableOptions', 'onSuccess', 'onError']));
