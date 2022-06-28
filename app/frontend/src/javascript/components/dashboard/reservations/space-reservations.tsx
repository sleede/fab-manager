import React, { useEffect, useState } from 'react';
import { FabPanel } from '../../base/fab-panel';
import { Reservation } from '../../../models/reservation';
import ReservationAPI from '../../../api/reservation';

interface SpaceReservationsProps {
  userId: number,
  onError: (message: string) => void,
}

/**
 * List all space reservations for the given user
 */
export const SpaceReservations: React.FC<SpaceReservationsProps> = ({ userId, onError }) => {
  const [reservations, setReservations] = useState<Array<Reservation>>([]);

  useEffect(() => {
    ReservationAPI.index({ user_id: userId, reservable_type: 'Space' })
      .then(res => setReservations(res))
      .catch(error => onError(error));
  }, []);

  return (
    <FabPanel className="space-reservations">
      {reservations.map(r => JSON.stringify(r))}
    </FabPanel>
  );
};
