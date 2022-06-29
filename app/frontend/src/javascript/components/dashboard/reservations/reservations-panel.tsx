import React, { ReactNode, useEffect, useState } from 'react';
import { FabPanel } from '../../base/fab-panel';
import { Reservation, ReservationSlot } from '../../../models/reservation';
import ReservationAPI from '../../../api/reservation';
import { useTranslation } from 'react-i18next';
import moment from 'moment';
import { Loader } from '../../base/loader';
import FormatLib from '../../../lib/format';
import { FabPopover } from '../../base/fab-popover';
import { useImmer } from 'use-immer';
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
  const [details, updateDetails] = useImmer<Record<number, boolean>>({});
  const [showMore, setShowMore] = useState<boolean>(false);

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
      return !!r.slots_attributes.find(s => filterSlot(s, state));
    });
  };

  /**
   * Check if the given slot if passed of futur
   */
  const filterSlot = (slot: ReservationSlot, state: 'passed' | 'futur'): boolean => {
    return (state === 'passed' && moment(slot.start_at).isBefore()) ||
      (state === 'futur' && moment(slot.start_at).isAfter());
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
      <li className="no-reservations">{t('app.logged.dashboard.reservations.reservations_panel.no_reservations')}</li>
    );
  };

  /**
   * Render the reservation in a user-friendly way
   */
  const renderReservation = (reservation: Reservation, state: 'passed' | 'futur'): ReactNode => {
    return (
      <li key={reservation.id} className="reservation">
        <a className={`reservation-title ${details[reservation.id] ? 'clicked' : ''}`} onClick={toggleDetails(reservation.id)}>
          {reservation.reservable.name} - {FormatLib.date(reservation.slots_attributes[0].start_at)}
        </a>
        {details[reservation.id] && <FabPopover title={t('app.logged.dashboard.reservations.reservations_panel.slots_details')}>
          {reservation.slots_attributes.filter(s => filterSlot(s, state)).map(
            slot => <span key={slot.id} className="slot-details">
              {FormatLib.date(slot.start_at)}, {FormatLib.time(slot.start_at)} - {FormatLib.time(slot.end_at)}
            </span>
          )}
        </FabPopover>}
      </li>
    );
  };

  const futur = reservationsByDate('futur');
  const passed = _.orderBy(reservationsByDate('passed'), r => r.slots_attributes[0].start_at, 'desc');

  return (
    <FabPanel className="reservations-panel" header={header()}>
      <h4>{t('app.logged.dashboard.reservations.reservations_panel.upcoming')}</h4>
      <ul>
        {futur.length === 0 && noReservations()}
        {futur.map(r => renderReservation(r, 'futur'))}
      </ul>
      <h4>{t('app.logged.dashboard.reservations.reservations_panel.passed')}</h4>
      <ul>
        {passed.length === 0 && noReservations()}
        {passed.slice(0, 10).map(r => renderReservation(r, 'passed'))}
        {passed.length > 10 && !showMore && <li className="show-more"><FabButton onClick={toggleShowMore}>
          {t('app.logged.dashboard.reservations.reservations_panel.show_more')}
        </FabButton></li>}
        {passed.length > 10 && showMore && passed.slice(10).map(r => renderReservation(r, 'passed'))}
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
