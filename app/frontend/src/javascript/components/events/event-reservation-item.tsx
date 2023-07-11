import React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Reservation } from '../../models/reservation';
import FormatLib from '../../lib/format';
import { IApplication } from '../../models/application';

declare const Application: IApplication;

interface EventReservationItemProps {
  reservation: Reservation;
}

/**
 * event reservation item component
 */
export const EventReservationItem: React.FC<EventReservationItemProps> = ({ reservation }) => {
  const { t } = useTranslation('logged');

  /**
   * Return the formatted localized date of the event
   */
  const formatDate = (): string => {
    return `${FormatLib.date(reservation.start_at)} ${FormatLib.time(reservation.start_at)} - ${FormatLib.time(reservation.end_at)}`;
  };

  /**
   * Build the ticket for event price category user reservation
   */
  const buildTicket = (ticket) => {
    return (
      <>
        <label>{t('app.logged.event_reservation_item.NUMBER_of_NAME_places_reserved', { NUMBER: ticket.booked, NAME: ticket.price_category.name })}</label>
        {reservation.booking_users_attributes.filter(u => u.event_price_category_id === ticket.event_price_category_id).map(u => {
          return (
            <p key={u.id} className='name'>{u.name}</p>
          );
        })}
      </>
    );
  };

  /**
   * Return the pre-registration status
   */
  const preRegistrationStatus = () => {
    if (!reservation.is_valid && !reservation.canceled_at && !reservation.is_paid) {
      return t('app.logged.event_reservation_item.in_the_process_of_validation');
    } else if (reservation.is_valid && !reservation.canceled_at && !reservation.is_paid) {
      return t('app.logged.event_reservation_item.settle_your_payment');
    } else if (reservation.is_paid && !reservation.canceled_at) {
      return t('app.logged.event_reservation_item.paid');
    } else if (reservation.canceled_at) {
      return t('app.logged.event_reservation_item.paid');
    }
  };

  return (
    <div className="event-reservation-item">
      <div className="event-reservation-item__event">
        <div className="infos">
          <label>{t('app.logged.event_reservation_item.event')}</label>
          <p>{reservation.event_title}</p>
          <span className='date'>{formatDate()}</span>
        </div>
        <div className="types">
          {/* {reservation.event_type === 'family' &&
            <span className="">{t('app.logged.event_reservation_item.family')}</span>
          }
          {reservation.event_type === 'nominative' &&
            <span className="">{t('app.logged.event_reservation_item.nominative')}</span>
          } */}
          {reservation.event_pre_registration &&
            // eslint-disable-next-line fabmanager/no-bootstrap, fabmanager/no-utilities
            <span className="badge text-xs bg-info">{t('app.logged.event_reservation_item.pre_registration')}</span>
          }
        </div>
      </div>
      <div className="event-reservation-item__reservation">
        <div className='list'>
          <label>{t('app.logged.event_reservation_item.NUMBER_normal_places_reserved', { NUMBER: reservation.nb_reserve_places })}</label>
          {reservation.booking_users_attributes.filter(u => !u.event_price_category_id).map(u => {
            return (
              <p key={u.id} className='name'>{u.name}</p>
            );
          })}
          {reservation.tickets.map(ticket => {
            return buildTicket(ticket);
          })}
        </div>
        {reservation.event_pre_registration &&
          <div className='status'>
            <label>{t('app.logged.event_reservation_item.tracking_your_reservation')}</label>
            <p className="">{preRegistrationStatus()}</p>
          </div>
        }
      </div>
    </div>
  );
};

Application.Components.component('eventReservationItem', react2angular(EventReservationItem, ['reservation']));
