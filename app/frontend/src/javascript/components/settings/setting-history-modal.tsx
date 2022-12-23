import type { Setting, SettingName } from '../../models/setting';
import React, { useEffect, useState } from 'react';
import { sortBy as _sortBy } from 'lodash';
import SettingAPI from '../../api/setting';
import { FabModal, ModalSize } from '../base/fab-modal';
import FormatLib from '../../lib/format';
import { useTranslation } from 'react-i18next';
import { useImmer } from 'use-immer';
import { HistoryValue } from '../../models/history-value';

interface CommonProps {
  isOpen: boolean,
  toggleModal: () => void,
  onError: (error: string) => void,
}

type SettingsProps =
  { setting: SettingName, settings?: never } |
  { setting?: never, settings: Array<SettingName> }

type SettingHistoryModalProps = CommonProps & SettingsProps;

/**
 * Shows the history of the changes for the provided setting.
 * Support for a cross history of several settings.
 */
export const SettingHistoryModal: React.FC<SettingHistoryModalProps> = ({ isOpen, toggleModal, setting, settings, onError }) => {
  const { t } = useTranslation('admin');

  const [settingData, setSettingData] = useImmer<Map<SettingName, Setting>>(new Map());
  const [history, setHistory] = useState<Array<HistoryValue & { setting: SettingName }>>([]);

  useEffect(() => {
    if (isOpen) {
      settings?.forEach((setting) => {
        SettingAPI.get(setting, { history: true }).then(res => {
          setSettingData(draft => {
            draft.set(setting, res);
          });
        }).catch(onError);
      });
      if (setting) {
        SettingAPI.get(setting, { history: true }).then(res => {
          setSettingData(draft => {
            draft.set(setting, res);
          });
        }).catch(onError);
      }
    }
  }, [isOpen]);

  useEffect(() => {
    setHistory(buildHistory());
  }, [settingData]);

  /**
   * Build the cross history for all the given settings
   */
  const buildHistory = () => {
    let history = [];
    for (const stng of settingData.keys()) {
      history = _sortBy(history.concat(settingData.get(stng as SettingName)?.history?.map(hv => {
        return {
          ...hv,
          setting: stng
        };
      })), 'created_at');
    }
    return history;
  };

  return (
    <FabModal isOpen={isOpen}
              className="setting-history-modal"
              toggleModal={toggleModal}
              width={ModalSize.large}
              title={t('app.admin.setting_history_modal.title')}
              closeButton>
      {history.length === 0 && <div>
        {t('app.admin.setting_history_modal.no_history')}
      </div>}
      {history.length > 0 && <table role="table">
        <thead>
          <tr>
            <th>{t('app.admin.setting_history_modal.setting')}</th>
            <th>{t('app.admin.setting_history_modal.value')}</th>
            <th>{t('app.admin.setting_history_modal.date')}</th>
            <th>{t('app.admin.setting_history_modal.operator')}</th>
          </tr>
        </thead>
        <tbody>
          {history.map(hv => <tr key={hv.id}>
            <td>{settingData.get(hv.setting).localized}</td>
            <td>{hv.value}</td>
            <td>{FormatLib.date(hv.created_at)}</td>
            <td>{hv.user.name}</td>
          </tr>)}
        </tbody>
      </table>}
    </FabModal>
  );
};
