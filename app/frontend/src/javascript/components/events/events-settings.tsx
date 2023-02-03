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
import { SettingName, SettingValue, eventsSettings } from '../../models/setting';
import { UnsavedFormAlert } from '../form/unsaved-form-alert';
import { UIRouter } from '@uirouter/angularjs';

declare const Application: IApplication;

interface EventsSettingsProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void
  uiRouter: UIRouter
}

/**
 * Events settings
 */
export const EventsSettings: React.FC<EventsSettingsProps> = ({ onError, onSuccess, uiRouter }) => {
  const { t } = useTranslation('admin');
  const { register, control, formState, handleSubmit, reset } = useForm<Record<SettingName, SettingValue>>();

  /** Link Events Banner Setting Names to generic keys expected by the Editorial Form */
  const bannerKeys: Record<EditorialKeys, SettingName> = {
    active_text_block: 'events_banner_active',
    text_block: 'events_banner_text',
    active_cta: 'events_banner_cta_active',
    cta_label: 'events_banner_cta_label',
    cta_url: 'events_banner_cta_url'
  };

  /** Callback triggered when the form is submitted: save the settings */
  const onSubmit: SubmitHandler<Record<SettingName, SettingValue>> = (data) => {
    SettingAPI.bulkUpdate(SettingLib.objectToBulkMap(data)).then(() => {
      onSuccess(t('app.admin.events_settings.update_success'));
    }, reason => {
      onError(reason);
    });
  };

  /** On component mount, fetch existing Events Banner Settings from API, and populate form with these values. */
  useEffect(() => {
    SettingAPI.query(eventsSettings)
      .then(settings => reset(SettingLib.bulkMapToObject(settings)))
      .catch(onError);
  }, []);

  return (
    <div className="events-settings">
      <header>
        <h2>{t('app.admin.events_settings.title')}</h2>
        <FabButton onClick={handleSubmit(onSubmit)} className='save-btn is-main'>{t('app.admin.events_settings.save')}</FabButton>
      </header>
      <form className="events-settings-content">
        <UnsavedFormAlert uiRouter={uiRouter} formState={formState} />
        <div className="settings-section">
          <EditorialBlockForm register={register}
                              control={control}
                              formState={formState}
                              keys={bannerKeys}
                              info={t('app.admin.events_settings.generic_text_block_info')} />
        </div>
      </form>
    </div>
  );
};

const EventsSettingsWrapper: React.FC<EventsSettingsProps> = (props) => {
  return (
    <Loader>
      <ErrorBoundary>
        <EventsSettings {...props} />
      </ErrorBoundary>
    </Loader>
  );
};

Application.Components.component('eventsSettings', react2angular(EventsSettingsWrapper, ['onError', 'onSuccess', 'uiRouter']));
