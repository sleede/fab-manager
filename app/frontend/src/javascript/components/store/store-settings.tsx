import { useEffect } from 'react';
import * as React from 'react';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { useTranslation } from 'react-i18next';
import { HtmlTranslate } from '../base/html-translate';
import { useForm, SubmitHandler } from 'react-hook-form';
import { FabAlert } from '../base/fab-alert';
import { FormRichText } from '../form/form-rich-text';
import { FabButton } from '../base/fab-button';
import SettingAPI from '../../api/setting';
import SettingLib from '../../lib/setting';
import { SettingName, SettingValue, storeSettings } from '../../models/setting';
import { FormSwitch } from '../form/form-switch';

declare const Application: IApplication;

interface StoreSettingsProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void
}

/**
 * Store settings display and edition
 */
export const StoreSettings: React.FC<StoreSettingsProps> = ({ onError, onSuccess }) => {
  const { t } = useTranslation('admin');
  const { control, handleSubmit, reset } = useForm<Record<SettingName, SettingValue>>();

  useEffect(() => {
    SettingAPI.query(storeSettings)
      .then(settings => {
        const data = SettingLib.bulkMapToObject(settings);
        reset(data);
      })
      .catch(onError);
  }, []);

  /**
   * Callback triggered when the form is submitted: save the settings
   */
  const onSubmit: SubmitHandler<Record<SettingName, SettingValue>> = (data) => {
    SettingAPI.bulkUpdate(SettingLib.objectToBulkMap(data)).then(() => {
      onSuccess(t('app.admin.store_settings.update_success'));
    }, reason => {
      onError(reason);
    });
  };

  return (
    <div className='store-settings'>
      <header>
        <h2>{t('app.admin.store_settings.title')}</h2>
      </header>
      <form onSubmit={handleSubmit(onSubmit)}>
        <div className="setting-section">
          <p className="section-title">{t('app.admin.store_settings.withdrawal_instructions')}</p>
          <FabAlert level="warning">
            <HtmlTranslate trKey="app.admin.store_settings.withdrawal_info" />
          </FabAlert>
          <FormRichText control={control}
                        heading
                        bulletList
                        link
                        limit={400}
                        id="store_withdrawal_instructions" />
        </div>
        <div className="setting-section">
          <p className="section-title">{t('app.admin.store_settings.store_hidden_title')}</p>
          <FabAlert level="warning">
            <HtmlTranslate trKey="app.admin.store_settings.store_hidden_info" />
          </FabAlert>
          <FormSwitch control={control} id="store_hidden" label={t('app.admin.store_settings.store_hidden')} />
        </div>
        <FabButton type='submit' className='save-btn'>{t('app.admin.store_settings.save')}</FabButton>
      </form>
    </div>
  );
};

const StoreSettingsWrapper: React.FC<StoreSettingsProps> = (props) => {
  return (
    <Loader>
      <StoreSettings {...props} />
    </Loader>
  );
};

Application.Components.component('storeSettings', react2angular(StoreSettingsWrapper, ['onError', 'onSuccess']));
