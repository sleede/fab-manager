import { Loader } from '../base/loader';
import { useEffect, useState } from 'react';
import NotificationPreferencesAPI from '../../api/notification_preference';
import { NotificationPreference, NotificationPreferencesByCategories } from '../../models/notification-preference';
import { NotificationCategoryNames } from '../../models/notification-type';
import { NotificationsCategory } from './notifications-category';
import NotificationTypesAPI from '../../api/notification_types';

interface NotificationsSettingsProps {
  onError: (message: string) => void
}

/**
 * Displays the list of notifications
 */
const NotificationsSettings: React.FC<NotificationsSettingsProps> = ({ onError }) => {
  const [preferencesByCategories, setPreferencesCategories] = useState<NotificationPreferencesByCategories>({});

  // From a default pattern of categories, and existing preferences and types retrieved from API,
  // this function builds an object with Notification Preferences sorted by categories.
  const fetchNotificationPreferences = async () => {
    let notificationPreferences: Array<NotificationPreference>;

    await NotificationPreferencesAPI.index()
      .then(userNotificationPreferences => {
        notificationPreferences = userNotificationPreferences;
      })
      .catch(onError);

    NotificationTypesAPI.index({ is_configurable: true })
      .then(notificationTypes => {
        // Initialize an object with every category as keys
        const newPreferencesByCategories: NotificationPreferencesByCategories = {};
        for (const categoryName of NotificationCategoryNames) {
          newPreferencesByCategories[categoryName] = [];
        }

        // For every notification type, we check if a notification preference already exists.
        // If there is none, we create one with default values.
        // Each Notification Preference is then placed in the right category.
        notificationTypes.forEach((notificationType) => {
          const existingPreference = notificationPreferences.find((notificationPreference) => {
            return notificationPreference.notification_type === notificationType.name;
          });
          newPreferencesByCategories[notificationType.category].push(
            existingPreference ||
            {
              notification_type: notificationType.name,
              in_system: true,
              email: true
            }
          );
        });
        setPreferencesCategories(newPreferencesByCategories);
      })
      .catch(onError);
  };

  // Triggers the fetch Notification Preferences on component mount
  useEffect(() => {
    fetchNotificationPreferences();
  }, []);

  return (
    <div className="notifications-settings">
      {Object.entries(preferencesByCategories).map((notificationPreferencesCategory) => (
        <NotificationsCategory
          key={notificationPreferencesCategory[0]}
          categoryName={notificationPreferencesCategory[0]}
          preferences={notificationPreferencesCategory[1]}
          onError={onError}
          refreshSettings={fetchNotificationPreferences} />
      ))
      }
    </div>
  );
};

const NotificationsSettingsWrapper: React.FC<NotificationsSettingsProps> = (props) => {
  return (
    <Loader>
      <NotificationsSettings {...props} />
    </Loader>
  );
};

export { NotificationsSettingsWrapper as NotificationsSettings };
