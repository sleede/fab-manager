import * as React from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { useTranslation } from 'react-i18next';
import { useForm, SubmitHandler } from 'react-hook-form';
import { FabButton } from '../base/fab-button';
import { EditorialBlockForm } from '../editorial-block/editorial-block-form';

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
          <EditorialBlockForm register={register}
                              control={control}
                              formState={formState}
                              info={t('app.admin.machines_settings.generic_text_block_info')} />
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
