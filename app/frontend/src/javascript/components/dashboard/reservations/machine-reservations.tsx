import React, { useEffect, useState } from 'react';
import { FabPanel } from '../../base/fab-panel';
import { Reservation } from '../../../models/reservation';
import ReservationAPI from '../../../api/reservation';

interface MachineReservationsProps {
  userId: number,
  onError: (message: string) => void,
}

/**
 * List all machine reservations for the given user
 */
export const MachineReservations: React.FC<MachineReservationsProps> = ({ userId, onError }) => {
  const [reservations, setReservations] = useState<Array<Reservation>>([]);

  useEffect(() => {
    ReservationAPI.index({ user_id: userId, reservable_type: 'Machine' })
      .then(res => setReservations(res))
      .catch(error => onError(error));
  }, []);

  return (
    <FabPanel className="machine-reservations">
      {reservations.map(r => JSON.stringify(r))}
    </FabPanel>
  );
};
