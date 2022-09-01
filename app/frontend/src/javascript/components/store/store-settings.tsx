import React from 'react';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { useTranslation } from 'react-i18next';
import { HtmlTranslate } from '../base/html-translate';
import { useForm, SubmitHandler } from 'react-hook-form';
import { FabAlert } from '../base/fab-alert';
import { FormRichText } from '../form/form-rich-text';
import { FabButton } from '../base/fab-button';

declare const Application: IApplication;

interface StoreSettingsProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void
}
interface Settings {
  withdrawal: string
}

/**
 * Shows store settings
 */
export const StoreSettings: React.FC<StoreSettingsProps> = (onError, onSuccess) => {
  const { t } = useTranslation('admin');

  const { control, handleSubmit } = useForm<Settings>();

  /**
   * Callback triggered when the form is submitted: process with the product creation or update.
   */
  const onSubmit: SubmitHandler<Settings> = (data) => {
    console.log(data);
  };

  return (
    <div className='store-settings'>
      <header>
        <h2>{t('app.admin.store_settings.title')}</h2>
      </header>
      <form onSubmit={handleSubmit(onSubmit)}>
        <p>{t('app.admin.store_settings.withdrawal_instructions')}</p>
        <FabAlert level="warning">
          <HtmlTranslate trKey="app.admin.store_settings.withdrawal_info" />
        </FabAlert>
        <FormRichText control={control}
                      heading
                      bulletList
                      link
                      limit={400}
                      id="withdrawal" />
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
