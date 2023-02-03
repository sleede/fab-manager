import React, { useEffect } from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { useTranslation } from 'react-i18next';
import { useForm, SubmitHandler } from 'react-hook-form';
import { FabButton } from '../base/fab-button';
import { EditorialKeys, EditorialBlockForm } from '../editorial-block/editorial-block-form';
import SettingAPI from '../../api/setting';
import SettingLib from '../../lib/setting';
import { SettingName, SettingValue, machinesSettings } from '../../models/setting';
import { UnsavedFormAlert } from '../form/unsaved-form-alert';
import { UIRouter } from '@uirouter/angularjs';

declare const Application: IApplication;

interface MachinesSettingsProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  beforeSubmit?: (data: Record<SettingName, SettingValue>) => void,
  uiRouter?: UIRouter
}

/**
 * Machines settings
 */
export const MachinesSettings: React.FC<MachinesSettingsProps> = ({ onError, onSuccess, beforeSubmit, uiRouter }) => {
  const { t } = useTranslation('admin');
  const { register, control, formState, handleSubmit, reset } = useForm<Record<SettingName, SettingValue>>();

  /** Link Machines Banner Setting Names to generic keys expected by the Editorial Form */
  const bannerKeys: Record<EditorialKeys, SettingName> = {
    active_text_block: 'machines_banner_active',
    text_block: 'machines_banner_text',
    active_cta: 'machines_banner_cta_active',
    cta_label: 'machines_banner_cta_label',
    cta_url: 'machines_banner_cta_url'
  };

  /** Callback triggered when the form is submitted: save the settings */
  const onSubmit: SubmitHandler<Record<SettingName, SettingValue>> = (data) => {
    if (typeof beforeSubmit === 'function') beforeSubmit(data);
    SettingAPI.bulkUpdate(SettingLib.objectToBulkMap(data)).then(() => {
      onSuccess(t('app.admin.machines_settings.successfully_saved'));
    }, reason => {
      onError(reason);
    });
  };

  /** On component mount, fetch existing Machines Banner Settings from API, and populate form with these values. */
  useEffect(() => {
    SettingAPI.query(machinesSettings)
      .then(settings => reset(SettingLib.bulkMapToObject(settings)))
      .catch(onError);
  }, []);

  return (
    <div className="machines-settings">
      <header>
        <h2>{t('app.admin.machines_settings.title')}</h2>
        <FabButton onClick={handleSubmit(onSubmit)} className='save-btn is-main'>{t('app.admin.machines_settings.save')}</FabButton>
      </header>
      <form className="machines-settings-content">
        {uiRouter && <UnsavedFormAlert uiRouter={uiRouter} formState={formState} />}
        <div className="settings-section">
          <EditorialBlockForm register={register}
                              control={control}
                              formState={formState}
                              keys={bannerKeys}
                              info={t('app.admin.machines_settings.generic_text_block_info')} />
        </div>
      </form>
    </div>
  );
};

const MachinesSettingsWrapper: React.FC<MachinesSettingsProps> = (props) => {
  return (
    <Loader>
      <ErrorBoundary>
        <MachinesSettings {...props} />
      </ErrorBoundary>
    </Loader>
  );
};

Application.Components.component('machinesSettings', react2angular(MachinesSettingsWrapper, ['onError', 'onSuccess', 'beforeSubmit', 'uiRouter']));
