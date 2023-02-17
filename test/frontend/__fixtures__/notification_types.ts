import { NotificationType } from '../../../app/frontend/src/javascript/models/notification-type';

const notificationTypes: Array<NotificationType> = [
  { id: 1, name: 'notify_admin_when_project_published', category: 'projects', is_configurable: true },
  { id: 2, name: 'notify_project_collaborator_to_valid', category: 'projects', is_configurable: true },
  { id: 3, name: 'notify_project_author_when_collaborator_valid', category: 'projects', is_configurable: true }
];

export default notificationTypes;
