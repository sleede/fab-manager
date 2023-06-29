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
        <div>{t('app.logged.event_reservation_item.NUMBER_of_NAME_places_reserved', { NUMBER: ticket.booked, NAME: ticket.price_category.name })}</div>
        {reservation.booking_users_attributes.filter(u => u.event_price_category_id === ticket.event_price_category_id).map(u => {
          return (
            <div key={u.id}>{u.name}</div>
          );
        })}
      </>
    );
  };

  /**
   * Return the pre-registration status
   */
  const preRegistrationStatus = () => {
    if (!reservation.validated_at && !reservation.canceled_at && !reservation.is_paid) {
      return t('app.logged.event_reservation_item.in_the_process_of_validation');
    } else if (reservation.validated_at && !reservation.canceled_at && !reservation.is_paid) {
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
        <div className="event-reservation-item__event__label">{t('app.logged.event_reservation_item.event')}</div>
        <div className="event-reservation-item__event__title">{reservation.event_title}</div>
        {reservation.event_type === 'family' &&
          <span className="">{t('app.logged.event_reservation_item.family')}</span>
        }
        {reservation.event_type === 'nominative' &&
          <span className="">{t('app.logged.event_reservation_item.nominative')}</span>
        }
        {reservation.event_pre_registration &&
          <span className="">{t('app.logged.event_reservation_item.pre_registration')}</span>
        }
        <span>{formatDate()}</span>
      </div>
      <div className="event-reservation-item__reservation">
        <div>
          <div>{t('app.logged.event_reservation_item.NUMBER_normal_places_reserved', { NUMBER: reservation.nb_reserve_places })}</div>
          {reservation.booking_users_attributes.filter(u => !u.event_price_category_id).map(u => {
            return (
              <div key={u.id}>{u.name}</div>
            );
          })}
          {reservation.tickets.map(ticket => {
            return buildTicket(ticket);
          })}
        </div>
        {reservation.event_pre_registration &&
          <div>
            <div>{t('app.logged.event_reservation_item.tracking_your_reservation')}</div>
            {preRegistrationStatus()}
          </div>
        }
      </div>
    </div>
  );
};

Application.Components.component('eventReservationItem', react2angular(EventReservationItem, ['reservation']));
