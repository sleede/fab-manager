import * as React from 'react';
import { useState } from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { useTranslation } from 'react-i18next';
import { FabAlert } from '../base/fab-alert';
import { useForm, SubmitHandler } from 'react-hook-form';
import { FormRichText } from '../form/form-rich-text';
import { FormSwitch } from '../form/form-switch';
import { FormInput } from '../form/form-input';
import { FabButton } from '../base/fab-button';

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

  // regular expression to validate the input fields
  const urlRegex = /^(https?:\/\/)([^.]+)\.(.{2,30})(\/.*)*\/?$/;

  const [isActiveAutoCancellation, setIsActiveAutoCancellation] = useState<boolean>(false);
  const [isActiveTextBlock, setIsActiveTextBlock] = useState<boolean>(false);
  const [isActiveCta, setIsActiveCta] = useState<boolean>(false);

  /**
   * Callback triggered when the auto cancellation switch has changed.
   */
  const toggleAutoCancellation = (value: boolean) => {
    setIsActiveAutoCancellation(value);
  };
  /**
   * Callback triggered when the text block switch has changed.
   */
  const toggleTextBlockSwitch = (value: boolean) => {
    setIsActiveTextBlock(value);
  };

  /**
   * Callback triggered when the CTA switch has changed.
   */
  const toggleTextBlockCta = (value: boolean) => {
    setIsActiveCta(value);
  };

  /**
   * Callback triggered when the CTA label has changed.
   */
  const handleCtaLabelChange = (event: React.ChangeEvent<HTMLInputElement>): void => {
    console.log('cta label:', event.target.value);
  };
  /**
   * Callback triggered when the cta url has changed.
   */
  const handleCtaUrlChange = (event: React.ChangeEvent<HTMLInputElement>): void => {
    console.log('cta url:', event.target.value);
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
      </header>
      <form onSubmit={handleSubmit(onSubmit)} className="trainings-settings-content">
        <div className="settings-section">
          <p className="section-title">{t('app.admin.trainings_settings.automatic_cancellation')}</p>
          <FabAlert level="warning">
            {t('app.admin.trainings_settings.automatic_cancellation_info')}
          </FabAlert>

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

        <div className="settings-section">
          <p className="section-title">{t('app.admin.trainings_settings.automatic_cancellation')}</p>
          <FabAlert level="warning">
            {t('app.admin.trainings_settings.generic_text_block_info')}
          </FabAlert>

          <FormSwitch id="active_text_block" control={control}
            onChange={toggleTextBlockSwitch} formState={formState}
            defaultValue={isActiveTextBlock}
            label={t('app.admin.trainings_settings.generic_text_block_switch')} />

          <FormRichText id="text_block"
                        control={control}
                        heading
                        limit={280}
                        disabled={!isActiveTextBlock} />

          {isActiveTextBlock && <>
            <FormSwitch id="active_cta" control={control}
              onChange={toggleTextBlockCta} formState={formState}
              label={t('app.admin.trainings_settings.cta_switch')} />

            {isActiveCta && <>
              <FormInput id="cta_label"
                        register={register}
                        rules={{ required: true }}
                        onChange={handleCtaLabelChange}
                        maxLength={40}
                        label={t('app.admin.trainings_settings.cta_label')} />
              <FormInput id="cta_url"
                        register={register}
                        rules={{ required: true, pattern: urlRegex }}
                        onChange={handleCtaUrlChange}
                        label={t('app.admin.trainings_settings.cta_url')} />
            </>}
          </>}
        </div>

        <FabButton type='submit' className='save-btn'>{t('app.admin.trainings_settings.save')}</FabButton>
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
