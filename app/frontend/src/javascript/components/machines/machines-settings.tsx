import * as React from 'react';
import { useState } from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { useTranslation } from 'react-i18next';
import { useForm, SubmitHandler } from 'react-hook-form';
import { FormRichText } from '../form/form-rich-text';
import { FormSwitch } from '../form/form-switch';
import { FormInput } from '../form/form-input';
import { FabButton } from '../base/fab-button';

declare const Application: IApplication;

interface MachinesSettingsProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Machines settings
 */
export const MachinesSettings: React.FC<MachinesSettingsProps> = () => {
  const { t } = useTranslation('admin');
  const { register, control, formState, handleSubmit } = useForm();

  // regular expression to validate the input fields
  const urlRegex = /^(https?:\/\/)([^.]+)\.(.{2,30})(\/.*)*\/?$/;

  const [isActiveAutoCancellation, setIsActiveAutoCancellation] = useState<boolean>(false);
  const [isActiveAuthorizationValidity, setIsActiveAuthorizationValidity] = useState<boolean>(false);
  const [isActiveTextBlock, setIsActiveTextBlock] = useState<boolean>(false);
  const [isActiveValidationRule, setIsActiveValidationRule] = useState<boolean>(false);
  const [isActiveCta, setIsActiveCta] = useState<boolean>(false);

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
    <div className="machines-settings">
      <header>
        <h2>{t('app.admin.machines_settings.title')}</h2>
        <FabButton onClick={handleSubmit(onSubmit)} className='save-btn is-main'>{t('app.admin.machines_settings.save')}</FabButton>
      </header>
      <form className="machines-settings-content">
        <div className="settings-section">
          <header>
            <p className="title">{t('app.admin.machines_settings.generic_text_block')}</p>
            <p className="description">{t('app.admin.machines_settings.generic_text_block_info')}</p>
          </header>

          <div className="content">
            <FormSwitch id="active_text_block" control={control}
              onChange={toggleTextBlockSwitch} formState={formState}
              defaultValue={isActiveTextBlock}
              label={t('app.admin.machines_settings.generic_text_block_switch')} />

            <FormRichText id="text_block"
                          control={control}
                          heading
                          limit={280}
                          disabled={!isActiveTextBlock} />

            {isActiveTextBlock && <>
              <FormSwitch id="active_cta" control={control}
                onChange={toggleTextBlockCta} formState={formState}
                label={t('app.admin.machines_settings.cta_switch')} />

              {isActiveCta && <>
                <FormInput id="cta_label"
                          register={register}
                          rules={{ required: true }}
                          onChange={handleCtaLabelChange}
                          maxLength={40}
                          label={t('app.admin.machines_settings.cta_label')} />
                <FormInput id="cta_url"
                          register={register}
                          rules={{ required: true, pattern: urlRegex }}
                          onChange={handleCtaUrlChange}
                          label={t('app.admin.machines_settings.cta_url')} />
              </>}
            </>}
          </div>
        </div>
      </form>
    </div>
  );
};

const MachinesSettingsWrapper: React.FC<MachinesSettingsProps> = (props) => {
  return (
    <Loader>
      <ErrorBoundary>
        <MachinesSettings {...props} />
      </ErrorBoundary>
    </Loader>
  );
};

Application.Components.component('machinesSettings', react2angular(MachinesSettingsWrapper, ['onError', 'onSuccess']));
