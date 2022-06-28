import React from 'react';
import { IApplication } from '../../../models/application';
import { react2angular } from 'react2angular';
import { MachineReservations } from './machine-reservations';
import { SpaceReservations } from './space-reservations';

declare const Application: IApplication;

interface ReservationsDashboardProps {
  onError: (message: string) => void,
  userId: number
}

/**
 * User dashboard showing everything about his spaces/machine reservations and also remaining credits
 */
const ReservationsDashboard: React.FC<ReservationsDashboardProps> = ({ onError, userId }) => {
  return (
    <div className="reservations-dashboard">
      <MachineReservations userId={userId} onError={onError} />
      <SpaceReservations userId={userId} onError={onError} />
    </div>
  );
};

Application.Components.component('reservationsDashboard', react2angular(ReservationsDashboard, ['onError', 'userId']));
