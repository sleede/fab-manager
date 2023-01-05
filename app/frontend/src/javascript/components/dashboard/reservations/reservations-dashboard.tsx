import { useEffect, useState } from 'react';
import * as React from 'react';
import { IApplication } from '../../../models/application';
import { react2angular } from 'react2angular';
import { ReservationsPanel } from './reservations-panel';
import SettingAPI from '../../../api/setting';
import { SettingName } from '../../../models/setting';
import { CreditsPanel } from './credits-panel';

declare const Application: IApplication;

interface ReservationsDashboardProps {
  onError: (message: string) => void,
  userId: number
}

/**
 * User dashboard showing everything about his spaces/machine reservations and also remaining credits
 */
const ReservationsDashboard: React.FC<ReservationsDashboardProps> = ({ onError, userId }) => {
  const [modules, setModules] = useState<Map<SettingName, string>>();

  useEffect(() => {
    SettingAPI.query(['spaces_module', 'machines_module'])
      .then(res => setModules(res))
      .catch(error => onError(error));
  }, []);

  return (
    <div className="reservations-dashboard">
      {modules?.get('machines_module') !== 'false' && <CreditsPanel userId={userId} onError={onError} reservableType="Machine" />}
      {modules?.get('spaces_module') !== 'false' && <CreditsPanel userId={userId} onError={onError} reservableType="Space" />}
      {modules?.get('machines_module') !== 'false' && <ReservationsPanel userId={userId} onError={onError} reservableType="Machine" />}
      {modules?.get('spaces_module') !== 'false' && <ReservationsPanel userId={userId} onError={onError} reservableType="Space" />}
    </div>
  );
};

Application.Components.component('reservationsDashboard', react2angular(ReservationsDashboard, ['onError', 'userId']));
