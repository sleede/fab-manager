import React, { useEffect, useState } from 'react';
import { FabModal, ModalSize } from '../base/fab-modal';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import SettingAPI from '../../api/setting';
import { SubmitHandler, useForm, useWatch } from 'react-hook-form';
import { SettingName, SettingValue } from '../../models/setting';
import { useTranslation } from 'react-i18next';
import SettingLib from '../../lib/setting';
import { FormSwitch } from '../form/form-switch';
import { FormInput } from '../form/form-input';
import { FabButton } from '../base/fab-button';
import { FabAlert } from '../base/fab-alert';
import { HtmlTranslate } from '../base/html-translate';
import { SettingHistoryModal } from '../settings/setting-history-modal';
import { useImmer } from 'use-immer';
import { enableMapSet } from 'immer';
import { ClockCounterClockwise } from 'phosphor-react';

declare const Application: IApplication;

const vatSettings: SettingName[] = ['invoice_VAT-rate', 'invoice_VAT-active', 'invoice_VAT-name', 'invoice_VAT-rate_Product', 'invoice_VAT-rate_Event',
  'invoice_VAT-rate_Machine', 'invoice_VAT-rate_Subscription', 'invoice_VAT-rate_Space', 'invoice_VAT-rate_Training'];

interface VatSettingsModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

enableMapSet();

/**
 * Modal dialog to configure VAT settings
 */
export const VatSettingsModal: React.FC<VatSettingsModalProps> = ({ isOpen, toggleModal, onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  const { handleSubmit, reset, control, register, formState } = useForm<Record<SettingName, SettingValue>>();
  const isActive = useWatch({ control, name: 'invoice_VAT-active' });
  const generalRate = useWatch({ control, name: 'invoice_VAT-rate' });

  const [modalWidth, setModalWidth] = useState<ModalSize>(ModalSize.small);
  const [advancedLabel, setAdvancedLabel] = useState<string>(t('app.admin.vat_settings_modal.advanced'));
  const [histories, setHistories] = useImmer<Map<SettingName, boolean>>(new Map());

  useEffect(() => {
    SettingAPI.query(vatSettings)
      .then(settings => {
        const data = SettingLib.bulkMapToObject(settings);
        reset(data);
      })
      .catch(onError);
  }, [isOpen]);

  /**
   * Callback triggered when the form is submitted: save the settings
   */
  const onSubmit: SubmitHandler<Record<SettingName, SettingValue>> = (data) => {
    SettingAPI.bulkUpdate(SettingLib.objectToBulkMap(data, { stripNaN: true })).then(() => {
      onSuccess(t('app.admin.vat_settings_modal.update_success'));
      toggleModal();
    }, reason => {
      onError(reason);
    });
  };

  /**
   * Show the panel allowing to configure a rate per resource type
   */
  const toggleAdvancedRates = () => {
    if (modalWidth === ModalSize.small) {
      setModalWidth(ModalSize.large);
      setAdvancedLabel(t('app.admin.vat_settings_modal.hide_advanced'));
    } else {
      setModalWidth(ModalSize.small);
      setAdvancedLabel(t('app.admin.vat_settings_modal.advanced'));
    }
  };

  /**
   * Open/closes the modal dialog showing the changes history for the given paramater name
   */
  const toggleHistoryModal = (name: SettingName) => {
    return () => {
      setHistories(draft => {
        draft.set(name, !draft.get(name));
      });
    };
  };

  return (
    <FabModal isOpen={isOpen}
              toggleModal={toggleModal}
              className="vat-settings-modal"
              width={modalWidth}
              title={t('app.admin.vat_settings_modal.title')}
              closeButton>
      <form onSubmit={handleSubmit(onSubmit)}>
        <div className={`panes ${modalWidth === ModalSize.large ? 'panes-both' : 'panes-one'}`}>
          <div className="pane">
            <FormSwitch control={control}
                        id="invoice_VAT-active"
                        label={t('app.admin.vat_settings_modal.enable_VAT')} />
            {isActive && <>
              <FormInput register={register}
                         id="invoice_VAT-name"
                         rules={{ required: true }}
                         formState={formState}
                         tooltip={t('app.admin.vat_settings_modal.VAT_name_help')}
                         label={t('app.admin.vat_settings_modal.VAT_name')} />
              <FormInput register={register}
                         id="invoice_VAT-rate"
                         rules={{ required: true }}
                         formState={formState}
                         tooltip={t('app.admin.vat_settings_modal.VAT_rate_help')}
                         type='number'
                         step={0.001}
                         label={t('app.admin.vat_settings_modal.VAT_rate')}
                         addOn={<ClockCounterClockwise size={24}/>}
                         addOnAriaLabel={t('app.admin.vat_settings_modal.show_history')}
                         addOnAction={toggleHistoryModal('invoice_VAT-rate')} />
              <SettingHistoryModal isOpen={histories.get('invoice_VAT-rate')}
                                   toggleModal={toggleHistoryModal('invoice_VAT-rate')}
                                   settings={['invoice_VAT-rate' as SettingName, 'invoice_VAT-active' as SettingName]}
                                   onError={onError} />
            </>}
            {modalWidth === ModalSize.large && <FabAlert level="warning">
              <HtmlTranslate trKey="app.admin.vat_settings_modal.multi_VAT_notice" options={{ RATE: String(generalRate) }} />
            </FabAlert>}
          </div>
          {modalWidth === ModalSize.large && <div className="pane">
            <FormInput register={register}
                       id="invoice_VAT-rate_Product"
                       type='number'
                       step={0.001}
                       label={t('app.admin.vat_settings_modal.VAT_rate_product')}
                       addOn={<ClockCounterClockwise size={24}/>}
                       addOnAriaLabel={t('app.admin.vat_settings_modal.show_history')}
                       addOnAction={toggleHistoryModal('invoice_VAT-rate_Product')} />
            <SettingHistoryModal isOpen={histories.get('invoice_VAT-rate_Product')}
                                 toggleModal={toggleHistoryModal('invoice_VAT-rate_Product')}
                                 setting={'invoice_VAT-rate_Product'}
                                 onError={onError} />
            <FormInput register={register}
                       id="invoice_VAT-rate_Event"
                       type='number'
                       step={0.001}
                       label={t('app.admin.vat_settings_modal.VAT_rate_event')}
                       addOn={<ClockCounterClockwise size={24}/>}
                       addOnAriaLabel={t('app.admin.vat_settings_modal.show_history')}
                       addOnAction={toggleHistoryModal('invoice_VAT-rate_Event')} />
            <SettingHistoryModal isOpen={histories.get('invoice_VAT-rate_Event')}
                                 toggleModal={toggleHistoryModal('invoice_VAT-rate_Event')}
                                 setting={'invoice_VAT-rate_Event'}
                                 onError={onError} />
            <FormInput register={register}
                       id="invoice_VAT-rate_Machine"
                       type='number'
                       step={0.001}
                       label={t('app.admin.vat_settings_modal.VAT_rate_machine')}
                       addOn={<ClockCounterClockwise size={24}/>}
                       addOnAriaLabel={t('app.admin.vat_settings_modal.show_history')}
                       addOnAction={toggleHistoryModal('invoice_VAT-rate_Machine')} />
            <SettingHistoryModal isOpen={histories.get('invoice_VAT-rate_Machine')}
                                 toggleModal={toggleHistoryModal('invoice_VAT-rate_Machine')}
                                 setting={'invoice_VAT-rate_Machine'}
                                 onError={onError} />
            <FormInput register={register}
                       id="invoice_VAT-rate_Subscription"
                       type='number'
                       step={0.001}
                       label={t('app.admin.vat_settings_modal.VAT_rate_subscription')}
                       addOn={<ClockCounterClockwise size={24}/>}
                       addOnAriaLabel={t('app.admin.vat_settings_modal.show_history')}
                       addOnAction={toggleHistoryModal('invoice_VAT-rate_Subscription')} />
            <SettingHistoryModal isOpen={histories.get('invoice_VAT-rate_Subscription')}
                                 toggleModal={toggleHistoryModal('invoice_VAT-rate_Subscription')}
                                 setting={'invoice_VAT-rate_Subscription'}
                                 onError={onError} />
            <FormInput register={register}
                       id="invoice_VAT-rate_Space"
                       type='number'
                       step={0.001}
                       label={t('app.admin.vat_settings_modal.VAT_rate_space')}
                       addOn={<ClockCounterClockwise size={24}/>}
                       addOnAriaLabel={t('app.admin.vat_settings_modal.show_history')}
                       addOnAction={toggleHistoryModal('invoice_VAT-rate_Space')} />
            <SettingHistoryModal isOpen={histories.get('invoice_VAT-rate_Space')}
                                 toggleModal={toggleHistoryModal('invoice_VAT-rate_Space')}
                                 setting={'invoice_VAT-rate_Space'}
                                 onError={onError} />
            <FormInput register={register}
                       id="invoice_VAT-rate_Training"
                       type='number'
                       step={0.001}
                       label={t('app.admin.vat_settings_modal.VAT_rate_training')}
                       addOn={<ClockCounterClockwise size={24}/>}
                       addOnAriaLabel={t('app.admin.vat_settings_modal.show_history')}
                       addOnAction={toggleHistoryModal('invoice_VAT-rate_Training')} />
            <SettingHistoryModal isOpen={histories.get('invoice_VAT-rate_Training')}
                                 toggleModal={toggleHistoryModal('invoice_VAT-rate_Training')}
                                 setting={'invoice_VAT-rate_Training'}
                                 onError={onError} />
          </div>}
        </div>
        <div className="actions">
          {isActive && <FabButton type="button" onClick={toggleAdvancedRates}>{advancedLabel}</FabButton>}
          <FabButton type="submit" className='save-btn'>{t('app.admin.vat_settings_modal.save')}</FabButton>
        </div>
      </form>
    </FabModal>
  );
};

const VatSettingsModalWrapper: React.FC<VatSettingsModalProps> = (props) => {
  return (
    <Loader>
      <VatSettingsModal {...props} />
    </Loader>
  );
};

Application.Components.component('vatSettingsModal', react2angular(VatSettingsModalWrapper, ['isOpen', 'toggleModal', 'onError', 'onSuccess']));
