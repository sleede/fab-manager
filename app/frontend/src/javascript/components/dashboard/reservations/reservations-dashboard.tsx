import { useEffect, useState } from 'react';
import * as React from 'react';
import { IApplication } from '../../../models/application';
import { react2angular } from 'react2angular';
import { ReservationsPanel } from './reservations-panel';
import SettingAPI from '../../../api/setting';
import { SettingName } from '../../../models/setting';
import { CreditsPanel } from './credits-panel';
import { useTranslation } from 'react-i18next';
import { PrepaidPacksPanel } from './prepaid-packs-panel';

declare const Application: IApplication;

interface ReservationsDashboardProps {
  onError: (message: string) => void,
  userId: number
}

/**
 * User dashboard showing everything about his spaces/machine reservations and also remaining credits
 */
const ReservationsDashboard: React.FC<ReservationsDashboardProps> = ({ onError, userId }) => {
  const { t } = useTranslation('logged');
  const [modules, setModules] = useState<Map<SettingName, string>>();

  useEffect(() => {
    SettingAPI.query(['spaces_module', 'machines_module'])
      .then(res => setModules(res))
      .catch(error => onError(error));
  }, []);

  return (
    <div className="reservations-dashboard">
      <div className="section">
        <p className="section-title">{t('app.logged.dashboard.reservations_dashboard.machine_section_title')}</p>
        {modules?.get('machines_module') !== 'false' && <CreditsPanel userId={userId} onError={onError} reservableType="Machine" />}
        <PrepaidPacksPanel userId={userId} onError={onError} />
        {modules?.get('machines_module') !== 'false' && <ReservationsPanel userId={userId} onError={onError} reservableType="Machine" />}
      </div>
      <div className="section">
        <p className="section-title">{t('app.logged.dashboard.reservations_dashboard.space_section_title')}</p>
        {modules?.get('spaces_module') !== 'false' && <CreditsPanel userId={userId} onError={onError} reservableType="Space" />}
        {modules?.get('spaces_module') !== 'false' && <ReservationsPanel userId={userId} onError={onError} reservableType="Space" />}
      </div>
    </div>
  );
};

Application.Components.component('reservationsDashboard', react2angular(ReservationsDashboard, ['onError', 'userId']));
