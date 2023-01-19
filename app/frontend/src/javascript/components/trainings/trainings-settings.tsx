import * as React from 'react';
import { useState } from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { useTranslation } from 'react-i18next';
import { useForm, SubmitHandler } from 'react-hook-form';
import { FormSwitch } from '../form/form-switch';
import { FormInput } from '../form/form-input';
import { FabButton } from '../base/fab-button';
import { EditorialBlockForm } from '../editorial-block/editorial-block-form';

declare const Application: IApplication;

interface TrainingsSettingsProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Trainings settings
 */
export const TrainingsSettings: React.FC<TrainingsSettingsProps> = () => {
  const { t } = useTranslation('admin');
  const { register, control, formState, handleSubmit } = useForm();

  const [isActiveAutoCancellation, setIsActiveAutoCancellation] = useState<boolean>(false);
  const [isActiveAuthorizationValidity, setIsActiveAuthorizationValidity] = useState<boolean>(false);
  const [isActiveValidationRule, setIsActiveValidationRule] = useState<boolean>(false);

  /**
   * Callback triggered when the auto cancellation switch has changed.
   */
  const toggleAutoCancellation = (value: boolean) => {
    setIsActiveAutoCancellation(value);
  };

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
  const onSubmit: SubmitHandler<any> = (data) => {
    console.log(data);
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
            <FormSwitch id="active_auto_cancellation" control={control}
              onChange={toggleAutoCancellation} formState={formState}
              defaultValue={isActiveAutoCancellation}
              label={t('app.admin.trainings_settings.automatic_cancellation_switch')} />

            {isActiveAutoCancellation && <>
              <FormInput id="auto_cancellation_threshold"
                      type="number"
                      register={register}
                      rules={{ required: isActiveAutoCancellation, min: 0 }}
                      step={1}
                      formState={formState}
                      label={t('app.admin.trainings_settings.automatic_cancellation_threshold')} />
              <FormInput id="auto_cancellation_deadline"
                      type="number"
                      register={register}
                      rules={{ required: isActiveAutoCancellation, min: 1 }}
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
