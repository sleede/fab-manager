import { Loader } from '../base/loader';
import { Notification } from '../../models/notification';
import FormatLib from '../../lib/format';
import { FabButton } from '../base/fab-button';
import { useTranslation } from 'react-i18next';

interface NotificationInlineProps {
  notification: Notification,
  onUpdate?: (Notification) => void
}

/**
 * Displays one notification
 */
const NotificationInline: React.FC<NotificationInlineProps> = ({ notification, onUpdate }) => {
  const { t } = useTranslation('logged');
  const createdAt = new Date(notification.created_at);

  // Call a parent component method to update the notification
  const update = () => onUpdate(notification);

  return (
    <div className="notification-inline">
      <div className="date">{ FormatLib.date(createdAt) } { FormatLib.time(createdAt) }</div>
      <div className="message" dangerouslySetInnerHTML={{ __html: notification.message.description }}/>
      {onUpdate && <FabButton onClick={update} className="is-secondary">{ t('app.logged.notification_inline.mark_as_read') }</FabButton>}
    </div>
  );
};

const NotificationInlineWrapper: React.FC<NotificationInlineProps> = (props) => {
  return (
    <Loader>
      <NotificationInline {...props} />
    </Loader>
  );
};

export { NotificationInlineWrapper as NotificationInline };
