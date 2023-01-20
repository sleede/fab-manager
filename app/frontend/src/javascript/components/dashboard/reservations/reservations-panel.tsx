import { ReactNode, useEffect, useState } from 'react';
import * as React from 'react';
import { FabPanel } from '../../base/fab-panel';
import { Reservation, SlotsReservation } from '../../../models/reservation';
import ReservationAPI from '../../../api/reservation';
import { useTranslation } from 'react-i18next';
import moment from 'moment';
import { Loader } from '../../base/loader';
import FormatLib from '../../../lib/format';
import _ from 'lodash';
import { FabButton } from '../../base/fab-button';

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
  const [showMore, setShowMore] = useState<boolean>(false);

  useEffect(() => {
    ReservationAPI.index({ user_id: userId, reservable_type: reservableType })
      .then(res => setReservations(res))
      .catch(error => onError(error));
  }, []);

  /**
   * Return the reservations for the given period
   */
  const reservationsByDate = (state: 'past' | 'futur'): Array<Reservation> => {
    return reservations.filter(r => {
      return !!r.slots_reservations_attributes.find(s => filterSlot(s, state));
    });
  };

  /**
   * Check if the given slot reservation if past of futur
   */
  const filterSlot = (sr: SlotsReservation, state: 'past' | 'futur'): boolean => {
    return (state === 'past' && moment(sr.slot_attributes.start_at).isBefore()) ||
      (state === 'futur' && moment(sr.slot_attributes.start_at).isAfter());
  };

  /**
   * Shows/hide the very old reservations list
   */
  const toggleShowMore = (): void => {
    setShowMore(!showMore);
  };

  /**
   * Display a placeholder when there's no reservation to display
   */
  const noReservations = (): ReactNode => {
    return (
      <span className="no-reservations">{t('app.logged.dashboard.reservations_dashboard.reservations_panel.no_reservation')}</span>
    );
  };

  /**
   * Check if all slots of the given reservation are canceled
   */
  const isCancelled = (reservation: Reservation): boolean => {
    return reservation.slots_reservations_attributes.map(sr => sr.canceled_at).every(ca => ca != null);
  };

  /**
   * Render the reservation in a user-friendly way
   */
  const renderReservation = (reservation: Reservation, state: 'past' | 'futur'): ReactNode => {
    return (
      <div key={reservation.id} className={`reservations-list-item ${isCancelled(reservation) ? 'cancelled' : ''}`}>
        <p className='name'>{reservation.reservable.name}</p>

        <div className="date">
          {reservation.slots_reservations_attributes.filter(s => filterSlot(s, state)).map(
            slotReservation => <p key={slotReservation.id} className={slotReservation.canceled_at ? 'cancelled' : ''}>
              {slotReservation.canceled_at ? t('app.logged.dashboard.reservations_dashboard.reservations_panel.cancelled_slot') : ''} {FormatLib.date(slotReservation.slot_attributes.start_at)} - {FormatLib.time(slotReservation.slot_attributes.start_at)} - {FormatLib.time(slotReservation.slot_attributes.end_at)}
            </p>
          )}
        </div>
      </div>
    );
  };

  const futur = reservationsByDate('futur');
  const past = _.orderBy(reservationsByDate('past'), r => r.slots_reservations_attributes[0].slot_attributes.start_at, 'desc');

  return (
    <FabPanel className="reservations-panel">
      <p className="title">{t('app.logged.dashboard.reservations_dashboard.reservations_panel.title')}</p>
      <div className="reservations">
        {futur.length === 0
          ? noReservations()
          : <div className="reservations-list">
              <span className="reservations-list-label name">{t('app.logged.dashboard.reservations_dashboard.reservations_panel.upcoming')}</span>
              <span className="reservations-list-label date">{t('app.logged.dashboard.reservations_dashboard.reservations_panel.date')}</span>

              {futur.map(r => renderReservation(r, 'futur'))}
            </div>
        }

        {past.length > 0 &&
          <div className="reservations-list is-history">
            <span className="reservations-list-label">{t('app.logged.dashboard.reservations_dashboard.reservations_panel.history')}</span>

            {past.slice(0, 5).map(r => renderReservation(r, 'past'))}
            {past.length > 5 && !showMore && <FabButton onClick={toggleShowMore} className="show-more is-black">
              {t('app.logged.dashboard.reservations_dashboard.reservations_panel.show_more')}
            </FabButton>}
            {past.length > 5 && showMore && past.slice(5).map(r => renderReservation(r, 'past'))}
          </div>
        }
      </div>
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
