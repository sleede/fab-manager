import { Notification, NotificationsIndex } from '../../../app/frontend/src/javascript/models/notification';

const newNotifications: Array<Notification> = [
  {
    id: 1,
    notification_type: 'notify_admin_when_project_published',
    notification_type_id: 1,
    created_at: '2023-02-03T14:42:34.678Z',
    is_read: false,
    message: {
      title: '',
      description: 'Decription of the first notification'
    }
  },
  {
    id: 2,
    notification_type: 'notify_project_collaborator_to_valid',
    notification_type_id: 2,
    created_at: '2023-02-03T14:42:34.678Z',
    is_read: false,
    message: {
      title: '',
      description: 'Decription of the second notification'
    }
  },
  {
    id: 3,
    notification_type: 'notify_project_author_when_collaborator_valid',
    notification_type_id: 3,
    created_at: '2023-02-03T14:42:34.678Z',
    is_read: false,
    message: {
      title: '',
      description: 'Decription of the third notification'
    }
  }
];

const notificationsIndex: NotificationsIndex = {
  notifications: newNotifications,
  totals: {
    total: 3,
    unread: 3
  }
};

export default notificationsIndex;
