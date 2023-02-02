import { Loader } from '../base/loader';
import { useTranslation } from 'react-i18next';
import { NotificationPreference } from '../../models/notification-preference';
import { NotificationForm } from './notification-form';
import { FabButton } from '../base/fab-button';
import NotificationPreferencesAPI from '../../api/notification_preference';

interface NotificationsCategoryProps {
  onError: (message: string) => void,
  refreshSettings: () => void,
  categoryName: string,
  preferences: Array<NotificationPreference>
}

/**
 * Displays the list of notifications
 */
const NotificationsCategory: React.FC<NotificationsCategoryProps> = ({ onError, categoryName, preferences, refreshSettings }) => {
  const { t } = useTranslation('logged');
  // Triggers a general update to enable all notifications for this category
  const enableAll = () => updateAll(true);

  // Triggers a general update to disable all notifications for this category
  const disableAll = () => updateAll(false);

  // Update all notifications for this category with a bulk_update.
  // This triggers a refresh of all the forms.
  const updateAll = async (value: boolean) => {
    const updatedPreferences: Array<NotificationPreference> = preferences.map(preference => {
      return { id: preference.id, notification_type: preference.notification_type, in_system: value, email: value };
    });
    await NotificationPreferencesAPI.bulk_update(updatedPreferences).catch(onError);
    refreshSettings();
  };

  return (
    <div className="notifications-category">
      <h2 className="category-name">{`${t(`app.logged.notifications_category.${categoryName}`)}, ${t('app.logged.notifications_category.notify_me_when')}`}</h2>
      <div className="category-content">
        <div className="category-actions">
          <FabButton className="category-action category-action-left" onClick={enableAll}>{t('app.logged.notifications_category.enable_all')}</FabButton>
          <FabButton className="category-action" onClick={disableAll}>{t('app.logged.notifications_category.disable_all')}</FabButton>
        </div>
        {preferences.map(preference => <NotificationForm key={preference.notification_type} preference={preference} onError={onError}/>)}
      </div>
    </div>
  );
};

const NotificationsCategoryWrapper: React.FC<NotificationsCategoryProps> = (props) => {
  return (
    <Loader>
      <NotificationsCategory {...props} />
    </Loader>
  );
};

export { NotificationsCategoryWrapper as NotificationsCategory };
