import React, { useState, useEffect } from 'react';
import { react2angular } from 'react2angular';
import StatusAPI from '../../../api/status';
import { IApplication } from '../../../models/application';
import { Loader } from '../../base/loader';
import { ProjectsSetting } from './../projects-setting';
import { ProjectSettingOption } from '../../../models/project-setting-option';
import { useTranslation } from 'react-i18next';
import { Status } from '../../../models/status';

declare const Application: IApplication;

interface StatusSettingsProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void
}

/**
 * Allows Admin to see, create, update and destroy the availables status on Projects.
*/
export const StatusSettings: React.FC<StatusSettingsProps> = ({ onError, onSuccess }) => {
  const { t } = useTranslation('admin');
  const [statusesOptions, setStatusesOptions] = useState<Array<Status>>([]);

  // Async function : post new status to API, then refresh status list
  const addOption = async (option: ProjectSettingOption) => {
    await StatusAPI.create({ name: option.name }).catch(onError);
    onSuccess(t('app.admin.status_settings.option_create_success'));
    fetchStatus();
  };

  // Async function : send delete action to API, then refresh status list
  const deleteOption = async (id: number) => {
    await StatusAPI.destroy(id).catch(onError);
    onSuccess(t('app.admin.status_settings.option_delete_success'));
    fetchStatus();
  };

  // Async function : send updated status to API, then refresh status list
  const updateOption = async (option: ProjectSettingOption) => {
    await StatusAPI.update({ id: option.id, name: option.name }).catch(onError);
    onSuccess(t('app.admin.status_settings.option_update_success'));
    fetchStatus();
  };

  // fetch list of Status from API and sort it by id
  const fetchStatus = () => {
    StatusAPI.index()
      .then(data => {
        setStatusesOptions(data.sort((a, b) => a.id - b.id));
      })
      .catch(onError);
  };

  // fetch list of Status on component mount
  useEffect(() => {
    fetchStatus();
  }, []);

  return (
    <div data-testid="status-settings">
      <ProjectsSetting
        options={statusesOptions}
        optionType= 'status'
        handleAdd={addOption}
        handleDelete={deleteOption}
        handleUpdate={updateOption} />
    </div>
  );
};

const StatusSettingsWrapper: React.FC<StatusSettingsProps> = (props) => {
  return (
    <Loader>
      <StatusSettings {...props} />
    </Loader>
  );
};

Application.Components.component('statusSettings', react2angular(StatusSettingsWrapper, ['onError', 'onSuccess']));
