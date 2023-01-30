import { useState, useEffect } from 'react';
import { IApplication } from '../../models/application';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { FabTabs } from '../base/fab-tabs';
import { NotificationsList } from './notifications-list';
import { useTranslation } from 'react-i18next';
import MemberAPI from '../../api/member';

declare const Application: IApplication;

interface NotificationsCenterProps {
  onError: (message: string) => void
}

/**
 * This Admin component groups two tabs : a list of notifications and the notifications settings
 */
export const NotificationsCenter: React.FC<NotificationsCenterProps> = ({ onError }) => {
  const { t } = useTranslation('admin');
  const [isAdmin, setIsAdmin] = useState<boolean>(false);

  useEffect(() => {
    MemberAPI.current()
      .then(data => {
        if (data.role === 'admin') setIsAdmin(true);
      });
  }, []);

  return (
    <>
      {isAdmin && <FabTabs defaultTab='notifications-list' tabs={[
        {
          id: 'notifications_settings',
          title: t('app.admin.notifications_center.notifications_settings'),
          content: 'to do notifications_settings'
        },
        {
          id: 'notifications-list',
          title: t('app.admin.notifications_center.notifications_list'),
          content: <NotificationsList onError={onError}/>
        }
      ]} />}
      {!isAdmin && <NotificationsList onError={onError}/>}
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
