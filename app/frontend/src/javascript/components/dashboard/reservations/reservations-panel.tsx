import React, { ReactNode, useEffect, useState } from 'react';
import { FabPanel } from '../../base/fab-panel';
import { Reservation } from '../../../models/reservation';
import ReservationAPI from '../../../api/reservation';
import { useTranslation } from 'react-i18next';
import moment from 'moment';
import { Loader } from '../../base/loader';
import FormatLib from '../../../lib/format';
import { FabPopover } from '../../base/fab-popover';
import { useImmer } from 'use-immer';

interface SpaceReservationsProps {
  userId: number,
  onError: (message: string) => void,
  reservableType: 'Machine' | 'Space'
}

/**
 * List all reservations for the given user and the given type
 */
const ReservationsPanel: React.FC<SpaceReservationsProps> = ({ userId, onError, reservableType }) => {
  const { t } = useTranslation('logged');

  const [reservations, setReservations] = useState<Array<Reservation>>([]);
  const [details, updateDetails] = useImmer<Record<number, boolean>>({});

  useEffect(() => {
    ReservationAPI.index({ user_id: userId, reservable_type: reservableType })
      .then(res => setReservations(res))
      .catch(error => onError(error));
  }, []);

  /**
   * Return the reservations for the given period
   */
  const reservationsByDate = (state: 'passed' | 'futur'): Array<Reservation> => {
    return reservations.filter(r => {
      return !!r.slots_attributes.find(s => {
        return (state === 'passed' && moment(s.start_at).isBefore()) ||
          (state === 'futur' && moment(s.start_at).isAfter());
      });
    });
  };

  /**
   * Panel title
   */
  const header = (): ReactNode => {
    return (
      <div>
        {t(`app.logged.dashboard.reservations.reservations_panel.title_${reservableType}`)}
      </div>
    );
  };

  /**
   * Show/hide the slots details for the given reservation
   */
  const toggleDetails = (reservationId: number): () => void => {
    return () => {
      updateDetails(draft => {
        draft[reservationId] = !draft[reservationId];
      });
    };
  };

  /**
   * Render the reservation in a user-friendly way
   */
  const renderReservation = (reservation: Reservation): ReactNode => {
    return (
      <li key={reservation.id} className="reservation">
        <a className={`reservation-title ${details[reservation.id] ? 'clicked' : ''}`} onClick={toggleDetails(reservation.id)}>{reservation.reservable.name}</a>
        {details[reservation.id] && <FabPopover title={t('app.logged.dashboard.reservations.reservations_panel.slots_details')}>
          {reservation.slots_attributes.map(
            (slot) => <span key={slot.id} className="slot-details">
              {FormatLib.date(slot.start_at)}, {FormatLib.time(slot.start_at)} - {FormatLib.time(slot.end_at)}
            </span>
          )}
        </FabPopover>}
      </li>
    );
  };

  return (
    <FabPanel className="reservations-panel" header={header()}>
      <h4>{t('app.logged.dashboard.reservations.reservations_panel.upcoming')}</h4>
      <ul>
        {reservationsByDate('futur').map(r => renderReservation(r))}
      </ul>
      <h4>{t('app.logged.dashboard.reservations.reservations_panel.passed')}</h4>
      <ul>
      {reservationsByDate('passed').map(r => renderReservation(r))}
      </ul>
    </FabPanel>
  );
};

const ReservationsPanelWrapper: React.FC<SpaceReservationsProps> = (props) => {
  return (
    <Loader>
      <ReservationsPanel {...props} />
    </Loader>
  );
};

export { ReservationsPanelWrapper as ReservationsPanel };
