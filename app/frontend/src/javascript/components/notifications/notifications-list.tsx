import { useEffect, useState } from 'react';
import { Loader } from '../base/loader';
import { Notification, NotificationsTotals } from '../../models/notification';
import NotificationAPI from '../../api/notification';
import { useTranslation } from 'react-i18next';
import { NotificationInline } from './notification-inline';
import { FabButton } from '../base/fab-button';

interface NotificationsListProps {
  onError: (message: string) => void
}

/**
 * Displays the list of notifications
 */
const NotificationsList: React.FC<NotificationsListProps> = ({ onError }) => {
  const { t } = useTranslation('logged');

  const [notifications, setNotifications] = useState<Array<Notification>>([]);
  const [totals, setTotals] = useState<NotificationsTotals>({ total: 0, unread: 0 });
  const [page, setPage] = useState<number>(1);

  const newNotifications = notifications.filter(notification => notification.is_read === false);
  const pastNotifications = notifications.filter(notification => notification.is_read === true);

  // Fetch Notification and Notification Totals from API
  const fetchNotifications = () => {
    NotificationAPI.index()
      .then(data => {
        setTotals(data.totals);
        setNotifications(data.notifications);
      })
      .catch(onError);
  };

  // Fetch Notifications and Notification Totals on component mount
  useEffect(() => {
    fetchNotifications();
  }, []);

  // Call Notifications API to set one notification as read, and fetch the updated Notifications & Totals
  const markAsRead = async (notification: Notification) => {
    await NotificationAPI.update(notification);
    fetchNotifications();
  };

  // Call Notifications API to set all notifications as read, and fetch the updated Notifications & Totals
  const markAllAsRead = async () => {
    await NotificationAPI.update_all();
    fetchNotifications();
  };

  // Calculate if they are notifications that are not yet displayed
  // If true, allows user to display more notifications
  const isMoreNotifications = (totals.total - notifications.length) > 0;

  // Call API to Load More Notifications
  const loadMoreNotifications = () => {
    if (isMoreNotifications) {
      const nextPage = page + 1;
      NotificationAPI.index(nextPage)
        .then(data => {
          setNotifications(prevState => [...prevState, ...data.notifications]);
          setPage(nextPage);
        })
        .catch(onError);
    }
  };

  return (
    <div className="notifications-list">
      <header className="notifications-header">
        <h2 className="title">{t('app.logged.notifications_list.notifications')}</h2>
        {totals.unread > 0 &&
          <FabButton onClick={markAllAsRead} className="is-main">
            { t('app.logged.notifications_list.mark_all_as_read')} ({totals.unread})
          </FabButton>}
      </header>
      {totals.unread === 0 && <p>{ t('app.logged.notifications_list.no_new_notifications') }</p>}
      <div>
        {newNotifications.map(notification => <NotificationInline key={notification.id} notification={notification} onUpdate={markAsRead} />)}
      </div>
      {pastNotifications.length > 0 &&
        <div className='archives'>
          <h3 className="title">{ t('app.logged.notifications_list.archives') }</h3>
          {pastNotifications.length === 0
            ? <p>{ t('app.logged.notifications_list.no_archived_notifications') }</p>
            : pastNotifications.map(notification => <NotificationInline key={notification.id} notification={notification} />)
          }
        </div>
      }
      {isMoreNotifications &&
        <FabButton className="is-black notifications-loader" onClick={loadMoreNotifications}>
          { t('app.logged.notifications_list.load_the_next_notifications') }
        </FabButton>
      }
    </div>
  );
};

const NotificationsListWrapper: React.FC<NotificationsListProps> = (props) => {
  return (
    <Loader>
      <NotificationsList {...props} />
    </Loader>
  );
};

export { NotificationsListWrapper as NotificationsList };
