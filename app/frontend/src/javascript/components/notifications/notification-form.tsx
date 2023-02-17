import { useEffect } from 'react';
import { Loader } from '../base/loader';
import { useTranslation } from 'react-i18next';
import { NotificationPreference } from '../../models/notification-preference';
import { useForm } from 'react-hook-form';
import { FormSwitch } from '../form/form-switch';
import NotificationPreferencesAPI from '../../api/notification_preference';

interface NotificationFormProps {
  onError: (message: string) => void,
  preference: NotificationPreference
}

/**
 * Displays the list of notifications
 */
const NotificationForm: React.FC<NotificationFormProps> = ({ preference, onError }) => {
  const { t } = useTranslation('logged');
  const { handleSubmit, formState, control, reset } = useForm<NotificationPreference>({ defaultValues: { ...preference } });

  // Create or Update (if id exists) a Notification Preference
  const onSubmit = (updatedPreference: NotificationPreference) => NotificationPreferencesAPI.update(updatedPreference).catch(onError);

  // Calls submit handler on every change of a Form Switch
  const handleChange = () => handleSubmit(onSubmit)();

  // Resets form on component mount, and if preference changes (happens when bulk updating a category)
  useEffect(() => {
    reset(preference);
  }, [preference]);

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="notification-form">
      <p className="notification-type">{t(`app.logged.notification_form.${preference.notification_type}`)}</p>
      <div className='form-actions'>
        <FormSwitch
          className="form-action"
          control={control}
          formState={formState}
          defaultValue={preference.email}
          id="email"
          label='email'
          onChange={handleChange}/>
        <FormSwitch
          className="form-action"
          control={control}
          formState={formState}
          defaultValue={preference.in_system}
          id="in_system"
          label='push'
          onChange={handleChange}/>
      </div>
    </form>
  );
};

const NotificationFormWrapper: React.FC<NotificationFormProps> = (props) => {
  return (
    <Loader>
      <NotificationForm {...props} />
    </Loader>
  );
};

export { NotificationFormWrapper as NotificationForm };
