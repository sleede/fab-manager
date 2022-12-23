import { IApplication } from '../../models/application';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { SubmitHandler, useForm, useWatch } from 'react-hook-form';
import { SettingName, SettingValue } from '../../models/setting';
import { useEffect } from 'react';
import SettingAPI from '../../api/setting';
import SettingLib from '../../lib/setting';
import { FabAlert } from '../base/fab-alert';
import { HtmlTranslate } from '../base/html-translate';
import { FormSwitch } from '../form/form-switch';
import { FabButton } from '../base/fab-button';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import FormatLib from '../../lib/format';
import { FormInput } from '../form/form-input';
import { UnsavedFormAlert } from '../form/unsaved-form-alert';
import type { UIRouter } from '@uirouter/angularjs';

declare const Application: IApplication;

const invoiceSettings: SettingName[] = ['invoice_prefix', 'payment_schedule_prefix', 'prevent_invoices_zero'];

interface InvoicesSettingsPanelProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  uiRouter: UIRouter
}

/**
 * Invoices settings display and edition
 */
export const InvoicesSettingsPanel: React.FC<InvoicesSettingsPanelProps> = ({ onError, onSuccess, uiRouter }) => {
  const { t } = useTranslation('admin');
  const { control, register, handleSubmit, reset, formState } = useForm<Record<SettingName, SettingValue>>();
  const invoicePrefix = useWatch({ control, name: 'invoice_prefix' });
  const schedulePrefix = useWatch({ control, name: 'payment_schedule_prefix' });

  const example = {
    id: Math.ceil(Math.random() * 100),
    idSchedule: Math.ceil(Math.random() * 100),
    date: FormatLib.dateFilename(new Date())
  };

  useEffect(() => {
    SettingAPI.query(invoiceSettings)
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
      onSuccess(t('app.admin.invoices_settings_panel.update_success'));
    }, reason => {
      onError(reason);
    });
  };

  return (
    <div className='invoices-settings-panel'>
      <form onSubmit={handleSubmit(onSubmit)}>
        <UnsavedFormAlert uiRouter={uiRouter} formState={formState} />
        <div className="setting-section">
          <p className="section-title">{t('app.admin.invoices_settings_panel.disable_invoices_zero')}</p>
          <FormSwitch control={control}
                      label={t('app.admin.invoices_settings_panel.disable_invoices_zero_label', { AMOUNT: FormatLib.price(0) })}
                      id="prevent_invoices_zero" />
        </div>
        <div className="setting-section">
          <p className="section-title" role="heading">{t('app.admin.invoices_settings_panel.filename')}</p>
          <FabAlert level="warning">
            <HtmlTranslate trKey="app.admin.invoices_settings_panel.filename_info" />
          </FabAlert>
          <FormInput register={register} id="invoice_prefix" label={t('app.admin.invoices_settings_panel.prefix')} />
          <div className="example">
            <span className="title" role="heading">{t('app.admin.invoices_settings_panel.example')}</span>
            <p className="content">
              {invoicePrefix}-{example.id}_{example.date}
            </p>
          </div>
        </div>
        <div className="setting-section">
          <p className="section-title" role="heading">{t('app.admin.invoices_settings_panel.schedule_filename')}</p>
          <FabAlert level="warning">
            <HtmlTranslate trKey="app.admin.invoices_settings_panel.schedule_filename_info" />
          </FabAlert>
          <FormInput register={register} id="payment_schedule_prefix" label={t('app.admin.invoices_settings_panel.prefix')} />
          <div className="example">
            <span className="title" role="heading">{t('app.admin.invoices_settings_panel.example')}</span>
            <p className="content">
              {schedulePrefix}-{example.idSchedule}_{example.date}
            </p>
          </div>
        </div>
        <div className="actions">
          <FabButton type='submit' className='save-btn'>{t('app.admin.invoices_settings_panel.save')}</FabButton>
        </div>
      </form>
    </div>
  );
};

const InvoicesSettingspanelWrapper: React.FC<InvoicesSettingsPanelProps> = (props) => {
  return (
    <Loader>
      <InvoicesSettingsPanel {...props} />
    </Loader>
  );
};

Application.Components.component('invoicesSettingsPanel', react2angular(InvoicesSettingspanelWrapper, ['onError', 'onSuccess', 'uiRouter']));
