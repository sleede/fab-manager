import { useEffect, useState } from 'react';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { EditorialBlock } from '../editorial-block/editorial-block';
import SettingAPI from '../../api/setting';
import SettingLib from '../../lib/setting';
import { SettingValue, eventsSettings } from '../../models/setting';

declare const Application: IApplication;

interface EventsEditorialBlockProps {
  onError: (message: string) => void
}

/**
 * This component displays to Users (public view) the editorial block (= banner) associated to events.
 */
export const EventsEditorialBlock: React.FC<EventsEditorialBlockProps> = ({ onError }) => {
  // Stores banner retrieved from API
  const [banner, setBanner] = useState<Record<string, SettingValue>>({});

  // Retrieve the settings related to the Events Banner from the API
  useEffect(() => {
    SettingAPI.query(eventsSettings)
      .then(settings => {
        setBanner({ ...SettingLib.bulkMapToObject(settings) });
      })
      .catch(onError);
  }, []);

  return (
    <>
      {banner.events_banner_active &&
        <EditorialBlock
          text={banner.events_banner_text}
          cta={banner.events_banner_cta_active && banner.events_banner_cta_label}
          url={banner.events_banner_cta_active && banner.events_banner_cta_url} />
      }
    </>
  );
};

const EventsEditorialBlockWrapper: React.FC<EventsEditorialBlockProps> = (props) => {
  return (
    <Loader>
      <EventsEditorialBlock {...props} />
    </Loader>
  );
};

Application.Components.component('eventsEditorialBlock', react2angular(EventsEditorialBlockWrapper, ['onError']));
