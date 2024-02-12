import { useEffect } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { SubmitHandler, useForm } from 'react-hook-form';
import { FabButton } from '../base/fab-button';
import { FormInput } from '../form/form-input';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { SettingName, SettingValue, accountingSettings } from '../../models/setting';
import SettingAPI from '../../api/setting';
import SettingLib from '../../lib/setting';
import { FormSwitch } from '../form/form-switch';
import { FabPanel } from '../base/fab-panel';

declare const Application: IApplication;

interface AccountingCodesSettingsProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void
}

/**
 * This component allows customization of accounting codes and other related settings
 */
export const AccountingCodesSettings: React.FC<AccountingCodesSettingsProps> = ({ onError, onSuccess }) => {
  const { t } = useTranslation('admin');
  const { handleSubmit, register, control, reset } = useForm<Record<SettingName, SettingValue>>();

  useEffect(() => {
    SettingAPI.query(accountingSettings)
      .then(settings => {
        const data = SettingLib.bulkMapToObject(settings);
        reset(data);
      })
      .catch(onError);
  }, []);

  /**
   * Callback triggered when the user clicks on 'save':
   * Update the settings on the API
   */
  const onSubmit: SubmitHandler<Record<SettingName, SettingValue>> = (data) => {
    SettingAPI.bulkUpdate(SettingLib.objectToBulkMap(data)).then(() => {
      onSuccess(t('app.admin.accounting_codes_settings.update_success'));
    }, reason => {
      onError(reason);
    });
  };

  return (
    <form className="accounting-codes-settings" onSubmit={handleSubmit(onSubmit)}>
      <FabPanel>
        <h4>{t('app.admin.accounting_codes_settings.advanced_accounting')}</h4>
        <FormSwitch control={control} id="advanced_accounting"
                    label={t('app.admin.accounting_codes_settings.enable_advanced')}
                    tooltip={t('app.admin.accounting_codes_settings.enable_advanced_help')} />
      </FabPanel>
      <FabPanel>
        <h4>{t('app.admin.accounting_codes_settings.financial')}</h4>
        <h5>{t('app.admin.accounting_codes_settings.card')}</h5>
        <div className="cards">
          <FormInput register={register} id="accounting_payment_card_journal_code" label={t('app.admin.accounting_codes_settings.journal_code')} />
          <FormInput register={register} id="accounting_payment_card_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_payment_card_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h5>{t('app.admin.accounting_codes_settings.wallet_debit')}</h5>
        <div className="wallets">
          <FormInput register={register} id="accounting_payment_wallet_journal_code" label={t('app.admin.accounting_codes_settings.journal_code')} />
          <FormInput register={register} id="accounting_payment_wallet_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_payment_wallet_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h5>{t('app.admin.accounting_codes_settings.transfer')}</h5>
        <div className="others">
          <FormInput register={register} id="accounting_payment_transfer_journal_code" label={t('app.admin.accounting_codes_settings.journal_code')} />
          <FormInput register={register} id="accounting_payment_transfer_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_payment_transfer_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h5>{t('app.admin.accounting_codes_settings.check')}</h5>
        <div className="others">
          <FormInput register={register} id="accounting_payment_check_journal_code" label={t('app.admin.accounting_codes_settings.journal_code')} />
          <FormInput register={register} id="accounting_payment_check_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_payment_check_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h5>{t('app.admin.accounting_codes_settings.other')}</h5>
        <div className="others">
          <FormInput register={register} id="accounting_payment_other_journal_code" label={t('app.admin.accounting_codes_settings.journal_code')} />
          <FormInput register={register} id="accounting_payment_other_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_payment_other_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h4>{t('app.admin.accounting_codes_settings.sales')}</h4>
        <h5>{t('app.admin.accounting_codes_settings.sales_journal')}</h5>
        <FormInput register={register} id="accounting_sales_journal_code" label={t('app.admin.accounting_codes_settings.journal_code')} />
        <h5>{t('app.admin.accounting_codes_settings.subscriptions')}</h5>
        <div className="subscriptions">
          <FormInput register={register} id="accounting_subscription_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_subscription_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h5>{t('app.admin.accounting_codes_settings.machine')}</h5>
        <div className="machine">
          <FormInput register={register} id="accounting_Machine_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_Machine_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h5>{t('app.admin.accounting_codes_settings.training')}</h5>
        <div className="training">
          <FormInput register={register} id="accounting_Training_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_Training_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h5>{t('app.admin.accounting_codes_settings.event')}</h5>
        <div className="events">
          <FormInput register={register} id="accounting_Event_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_Event_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h5>{t('app.admin.accounting_codes_settings.space')}</h5>
        <div className="space">
          <FormInput register={register} id="accounting_Space_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_Space_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h5>{t('app.admin.accounting_codes_settings.prepaid_pack')}</h5>
        <div className="prepaid_pack">
          <FormInput register={register} id="accounting_Pack_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_Pack_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h5>{t('app.admin.accounting_codes_settings.product')}</h5>
        <div className="product">
          <FormInput register={register} id="accounting_Product_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_Product_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h5>{t('app.admin.accounting_codes_settings.error')}</h5>
        <div className="error">
          <FormInput register={register} id="accounting_Error_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_Error_label"
                     label={t('app.admin.accounting_codes_settings.label')}
                     tooltip={t('app.admin.accounting_codes_settings.error_help')} />
        </div>
        <h4>{t('app.admin.accounting_codes_settings.wallet_credit')}</h4>
        <div className="wallets">
          <FormInput register={register} id="accounting_wallet_journal_code" label={t('app.admin.accounting_codes_settings.journal_code')} />
          <FormInput register={register} id="accounting_wallet_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_wallet_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
        <h4>{t('app.admin.accounting_codes_settings.VAT')}</h4>
        <div className="vat">
          <FormInput register={register} id="accounting_VAT_journal_code" label={t('app.admin.accounting_codes_settings.journal_code')} />
          <FormInput register={register} id="accounting_VAT_code" label={t('app.admin.accounting_codes_settings.code')} />
          <FormInput register={register} id="accounting_VAT_label" label={t('app.admin.accounting_codes_settings.label')} />
        </div>
      </FabPanel>
      <FabPanel className="actions">
        <FabButton type="submit" className="is-info submit-btn">
          {t('app.admin.accounting_codes_settings.save')}
        </FabButton>
      </FabPanel>
    </form>
  );
};

Application.Components.component('accountingCodesSettings', react2angular(AccountingCodesSettings, ['onSuccess', 'onError']));
