import * as React from 'react';
import { useEffect, useState } from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { useTranslation } from 'react-i18next';
import { useForm, SubmitHandler, useWatch } from 'react-hook-form';
import { FormSwitch } from '../form/form-switch';
import { FormInput } from '../form/form-input';
import { FabButton } from '../base/fab-button';
import { EditorialBlockForm } from '../editorial-block/editorial-block-form';
import { SettingName, SettingValue, trainingSettings } from '../../models/setting';
import SettingAPI from '../../api/setting';
import SettingLib from '../../lib/setting';

declare const Application: IApplication;

interface TrainingsSettingsProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Trainings settings
 */
export const TrainingsSettings: React.FC<TrainingsSettingsProps> = ({ onError, onSuccess }) => {
  const { t } = useTranslation('admin');
  const { register, control, formState, handleSubmit, reset } = useForm<Record<SettingName, SettingValue>>();

  const isActiveAutoCancellation = useWatch({ control, name: 'trainings_auto_cancel' }) as boolean;
  const [isActiveAuthorizationValidity, setIsActiveAuthorizationValidity] = useState<boolean>(false);
  const [isActiveValidationRule, setIsActiveValidationRule] = useState<boolean>(false);

  useEffect(() => {
    SettingAPI.query(trainingSettings)
      .then(settings => {
        const data = SettingLib.bulkMapToObject(settings);
        reset(data);
      })
      .catch(onError);
  }, []);

  /**
   * Callback triggered when the authorisation validity switch has changed.
   */
  const toggleAuthorizationValidity = (value: boolean) => {
    setIsActiveAuthorizationValidity(value);
  };

  /**
   * Callback triggered when the authorisation validity switch has changed.
   */
  const toggleValidationRule = (value: boolean) => {
    setIsActiveValidationRule(value);
  };

  /**
   * Callback triggered when the form is submitted: save the settings
   */
  const onSubmit: SubmitHandler<Record<SettingName, SettingValue>> = (data) => {
    SettingAPI.bulkUpdate(SettingLib.objectToBulkMap(data)).then(() => {
      onSuccess(t('app.admin.trainings_settings.update_success'));
    }, reason => {
      onError(reason);
    });
  };

  return (
    <div className="trainings-settings">
      <header>
        <h2>{t('app.admin.trainings_settings.title')}</h2>
        <FabButton onClick={handleSubmit(onSubmit)} className='save-btn is-main'>{t('app.admin.trainings_settings.save')}</FabButton>
      </header>
      <form className="trainings-settings-content">
        <div className="settings-section">
          <EditorialBlockForm register={register}
                              control={control}
                              formState={formState}
                              info={t('app.admin.trainings_settings.generic_text_block_info')} />
        </div>

        <div className="settings-section">
          <header>
            <p className="title">{t('app.admin.trainings_settings.automatic_cancellation')}</p>
            <p className="description">{t('app.admin.trainings_settings.automatic_cancellation_info')}</p>
          </header>

          <div className="content">
            <FormSwitch id="trainings_auto_cancel" control={control}
              formState={formState}
              defaultValue={isActiveAutoCancellation}
              label={t('app.admin.trainings_settings.automatic_cancellation_switch')} />

            {isActiveAutoCancellation && <>
              <FormInput id="trainings_auto_cancel_threshold"
                      type="number"
                      register={register}
                      rules={{ required: isActiveAutoCancellation, min: 0 }}
                      step={1}
                      nullable
                      formState={formState}
                      label={t('app.admin.trainings_settings.automatic_cancellation_threshold')} />
              <FormInput id="trainings_auto_cancel_deadline"
                      type="number"
                      register={register}
                      rules={{ required: isActiveAutoCancellation, min: 1 }}
                      nullable
                      step={1}
                      formState={formState}
                      label={t('app.admin.trainings_settings.automatic_cancellation_deadline')} />
            </>}
          </div>
        </div>

        <div className="settings-section">
          <header>
            <p className="title">{t('app.admin.trainings_settings.authorization_validity')}</p>
            <p className="description">{t('app.admin.trainings_settings.authorization_validity_info')}</p>
          </header>
          <div className="content">
            <FormSwitch id="authorization_validity" control={control}
              onChange={toggleAuthorizationValidity} formState={formState}
              defaultValue={isActiveAuthorizationValidity}
              label={t('app.admin.trainings_settings.authorization_validity_switch')} />
            {isActiveAuthorizationValidity && <>
              <FormInput id="authorization_validity_duration"
                      type="number"
                      register={register}
                      rules={{ required: isActiveAuthorizationValidity, min: 1 }}
                      step={1}
                      formState={formState}
                      label={t('app.admin.trainings_settings.authorization_validity_period')} />
            </>}
          </div>
        </div>

        <div className="settings-section">
          <header>
            <p className="title">{t('app.admin.trainings_settings.validation_rule')}</p>
            <p className="description">{t('app.admin.trainings_settings.validation_rule_info')}</p>
          </header>
          <div className="content">
            <FormSwitch id="validation_rule" control={control}
              onChange={toggleValidationRule} formState={formState}
              defaultValue={isActiveValidationRule}
              label={t('app.admin.trainings_settings.validation_rule_switch')} />
            {isActiveValidationRule && <>
              <FormInput id="validation_rule_period"
                      type="number"
                      register={register}
                      rules={{ required: isActiveValidationRule, min: 1 }}
                      step={1}
                      formState={formState}
                      label={t('app.admin.trainings_settings.validation_rule_period')} />
            </>}
          </div>
        </div>
      </form>
    </div>
  );
};

const TrainingsSettingsWrapper: React.FC<TrainingsSettingsProps> = (props) => {
  return (
    <Loader>
      <ErrorBoundary>
        <TrainingsSettings {...props} />
      </ErrorBoundary>
    </Loader>
  );
};

Application.Components.component('trainingsSettings', react2angular(TrainingsSettingsWrapper, ['onError', 'onSuccess']));
