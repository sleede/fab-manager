import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { Event } from '../../models/event';
import FormatLib from '../../lib/format';

import defaultImage from '../../../../images/default-image.png';

declare const Application: IApplication;

interface EventCardProps {
  event: Event,
  cardType: 'sm' | 'md' | 'lg'
}

/**
 * This component is a box showing the picture of the given event, and a short description of it.
 */
export const EventCard: React.FC<EventCardProps> = ({ event, cardType }) => {
  const { t } = useTranslation('public');

  /**
   * Format description to remove HTML tags and set a maximum character count
   */
  const formatText = (text: string, count: number) => {
    text = text.replace(/(<\/p>|<\/h4>|<\/h5>|<\/h6>|<\/pre>|<\/blockquote>)/g, '\n');
    text = text.replace(/<br\s*\/?>/g, '\n');
    text = text.replace(/<\/?\w+[^>]*>/g, '');
    if (text.length > count) {
      text = text.slice(0, count) + '…';
    }
    text = text.replace(/\n+/g, '<br />');
    return text;
  };

  /**
   * Return the formatted localized date of the event
   */
  const formatDate = (): string => {
    const startDate = new Date(event.start_date);
    const endDate = new Date(event.end_date);
    const singleDayEvent = startDate.getFullYear() === endDate.getFullYear() &&
    startDate.getMonth() === endDate.getMonth() &&
    startDate.getDate() === endDate.getDate();
    return singleDayEvent
      ? t('app.public.event_card.on_the_date', { DATE: FormatLib.date(event.start_date) })
      : t('app.public.event_card.from_date_to_date', { START: FormatLib.date(event.start_date), END: FormatLib.date(event.end_date) });
  };

  /**
   * Return the formatted localized hours of the event
   */
  const formatTime = (): string => {
    return event.all_day
      ? t('app.public.event_card.all_day')
      : t('app.public.event_card.from_time_to_time', { START: event.start_time, END: event.end_time });
  };

  return (
    <div className={`event-card event-card--${cardType}`}>
      {event.event_image_attributes
        ? <div className="event-card-picture">
            <img src={event.event_image_attributes.attachment_url} alt={event.event_image_attributes.attachment_name} onError={({ currentTarget }) => {
              currentTarget.onerror = null;
              currentTarget.src = defaultImage;
            }} />
          </div>
        : cardType !== 'sm' &&
          <div className="event-card-picture">
            <i className="fas fa-image"></i>
          </div>
      }
      <div className="event-card-desc">
        <header>
          <span className={`badge bg-${event.category.slug}`}>{event.category.name}</span>
          <p className='title'>{event?.title}</p>
        </header>
        {cardType !== 'sm' &&
          <p dangerouslySetInnerHTML={{ __html: formatText(event.description, cardType === 'md' ? 500 : 400) }}></p>
        }
      </div>
      <div className="event-card-info">
        {cardType !== 'md' &&
          <p>
            {formatDate()}
            <span>{formatTime()}</span>
          </p>
        }
        <div className="grid">
          {cardType !== 'md' &&
            event.event_themes.map(theme => {
              return (<div key={theme.name} className="grid-item">
                <i className="fa fa-tags"></i>
                <h6>{theme.name}</h6>
              </div>);
            })
          }
          {(cardType !== 'md' && event.age_range) &&
            <div className="grid-item">
              <i className="fa fa-users"></i>
              <h6>{event.age_range?.name}</h6>
            </div>
          }
          {cardType === 'md' &&
            <>
              <div className="grid-item">
                <i className="fa fa-calendar"></i>
                <h6>{formatDate()}</h6>
              </div>
              <div className="grid-item">
                <i className="fa fa-clock"></i>
                <h6>{formatTime()}</h6>
              </div>
            </>
          }
          <div className="grid-item">
            <i className="fa fa-user"></i>
            {event.nb_free_places > 0 && <h6>{t('app.public.event_card.still_available') + event.nb_free_places}</h6>}
            {event.nb_total_places > 0 && event.nb_free_places <= 0 && <h6>{t('app.public.event_card.event_full')}</h6>}
            {!event.nb_total_places && <h6>{t('app.public.event_card.without_reservation')}</h6>}
          </div>
          <div className="grid-item">
            <i className="fa fa-bookmark"></i>
            {event.amount === 0 && <h6>{t('app.public.event_card.free_admission')}</h6>}
            {event.amount > 0 && <h6>{t('app.public.event_card.full_price') + FormatLib.price(event.amount)}</h6>}
          </div>
        </div>
      </div>
    </div>
  );
};

const EventCardWrapper: React.FC<EventCardProps> = ({ event, cardType }) => {
  return (
    <Loader>
      <EventCard event={event} cardType={cardType} />
    </Loader>
  );
};

Application.Components.component('eventCard', react2angular(EventCardWrapper, ['event', 'cardType']));
