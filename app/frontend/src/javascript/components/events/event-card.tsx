import React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { Event } from '../../models/event';
import FormatLib from '../../lib/format';

declare const Application: IApplication;

interface EventCardProps {
  event: Event,
  cardType: 'sm' | 'md' | 'lg'
}

export const EventCard: React.FC<EventCardProps> = ({ event, cardType = 'sm' }) => {
  const { t } = useTranslation('public');
  console.log(event);
  /**
   * Format description to remove HTML tags and set a maximum character count
   */
  const formatText = (text: string, count: number) => {
    text = text.replace(/(<\/p>|<\/h4>|<\/h5>|<\/h6>|<\/pre>|<\/blockquote>)/g, '\n');
    text = text.replace(/<br\s*\/?>/g, '\n');
    text = text.replace(/<\/?\w+[^>]*>/g, '');
    text = text.replace(/\n+/g, '<br />');
    if (text.length > count) {
      return text.slice(0, count) + '...';
    }
    return text;
  };

  /**
   * Return the formatted localized date of the event
   */
  const formatDate = (): string => {
    // FIXME: typeof event.all_day = sting ?
    return event.all_day === 'true'
      ? t('app.public.home.from_date_to_date', { START: FormatLib.date(event.start_date), END: FormatLib.date(event.end_date) })
      : t('app.public.home.on_the_date', { DATE: FormatLib.date(event.start_date) });
  };

  /**
   * Return the formatted localized hours of the event
   */
  const formatTime = (): string => {
    // FIXME: typeof event.all_day = sting ?
    return event.all_day === 'true'
      ? t('app.public.home.all_day')
      : t('app.public.home.from_time_to_time', { START: FormatLib.time(event.start_date), END: FormatLib.time(event.end_date) });
  };

  /**
   * Link to event by id
   */
  const showEvent = (id: number) => {
    // TODO: ???
    console.log(id);
  };

  return (
    <div className={`event-card event-card--${cardType}`} onClick={() => showEvent(event.id)}>
      <div className="event-card-picture">
        {event.event_image
          ? <img src={event.event_image} alt="" />
          : <i className="fas fa-image"></i>
        }
      </div>
      <div className="event-card-desc">
        <header>
          <p className='title'>{event?.title}</p>
          <span className={`badge bg-${event.category.slug}`}>{event.category.name}</span>
        </header>
        {cardType !== 'sm' &&
          <p dangerouslySetInnerHTML={{ __html: formatText(event.description, 500) }}></p>
        }
      </div>
      <div className="event-card-info">
        {cardType !== 'md' && <p>{formatDate()}</p> }
        <div className="grid">
          {cardType === 'sm' &&
            event.event_themes.map(theme => {
              return (<div key={theme.name} className="grid-item">
                <i className="fa fa-tags"></i>
                <h6>{theme.name}</h6>
              </div>);
            })
          }
          {(cardType === 'sm' && event.age_range) &&
            <div className="grid-item">
              <i className="fa fa-users"></i>
              <h6>{event.age_range?.name}</h6>
            </div>
          }
          {cardType === 'md' &&
            <div className="grid-item">
              <i className="fa fa-calendar"></i>
              <h6>{formatDate()}</h6>
            </div>
          }
          <div className="grid-item">
            {cardType !== 'sm' && <i className="fa fa-clock"></i>}
            <h6>{formatTime()}</h6>
          </div>
          <div className="grid-item">
            {cardType !== 'sm' && <i className="fa fa-user"></i>}
            {event.nb_free_places > 0 && <h6>{t('app.public.home.still_available') + event.nb_free_places}</h6>}
            {event.nb_total_places > 0 && event.nb_free_places <= 0 && <h6>{t('app.public.home.event_full')}</h6>}
            {!event.nb_total_places && <h6>{t('app.public.home.without_reservation')}</h6>}
          </div>
          <div className="grid-item">
            {cardType !== 'sm' && <i className="fa fa-bookmark"></i>}
            {event.amount === 0 && <h6>{t('app.public.home.free_admission')}</h6>}
            {/* TODO: Display currency ? */}
            {event.amount > 0 && <h6>{t('app.public.home.full_price') + event.amount}</h6>}
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
