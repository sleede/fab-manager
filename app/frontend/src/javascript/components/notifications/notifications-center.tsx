import { useState, useEffect } from 'react';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { FabTabs } from '../base/fab-tabs';
import { NotificationsList } from './notifications-list';
import { NotificationsSettings } from './notifications-settings';
import { useTranslation } from 'react-i18next';
import MemberAPI from '../../api/member';
import { UserRole } from '../../models/user';

declare const Application: IApplication;

interface NotificationsCenterProps {
  onError: (message: string) => void
}

/**
 * This Admin component groups two tabs : a list of notifications and the notifications settings
 */
export const NotificationsCenter: React.FC<NotificationsCenterProps> = ({ onError }) => {
  const { t } = useTranslation('logged');
  const [role, setRole] = useState<UserRole>();

  useEffect(() => {
    MemberAPI.current()
      .then(data => setRole(data.role))
      .catch(onError);
  }, []);

  return (
    <>
      {role === 'admin' && <FabTabs defaultTab='notifications_settings' tabs={[
        {
          id: 'notifications_settings',
          title: t('app.logged.notifications_center.notifications_settings'),
          content: <NotificationsSettings onError={onError}/>
        },
        {
          id: 'notifications-list',
          title: t('app.logged.notifications_center.notifications_list'),
          content: <NotificationsList onError={onError}/>
        }
      ]} />}
      {role !== 'admin' && <NotificationsList onError={onError}/>}
    </>
  );
};

const NotificationsCenterWrapper: React.FC<NotificationsCenterProps> = (props) => {
  return (
    <Loader>
      <NotificationsCenter {...props} />
    </Loader>
  );
};

Application.Components.component('notificationsCenter', react2angular(NotificationsCenterWrapper, ['onError']));
