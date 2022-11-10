import React, { useEffect, useState } from 'react';
import { SubmitHandler, useForm, useWatch } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import { FormInput } from '../form/form-input';
import { FormImageUpload } from '../form/form-image-upload';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { FormRichText } from '../form/form-rich-text';
import { FormSwitch } from '../form/form-switch';
import { FabButton } from '../base/fab-button';
import { Training } from '../../models/training';
import TrainingAPI from '../../api/training';
import { FormMultiSelect } from '../form/form-multi-select';
import MachineAPI from '../../api/machine';
import { Machine } from '../../models/machine';
import { SelectOption } from '../../models/select';
import SettingAPI from '../../api/setting';
import { Setting } from '../../models/setting';
import { AdvancedAccountingForm } from '../accounting/advanced-accounting-form';

declare const Application: IApplication;

interface TrainingFormProps {
  action: 'create' | 'update',
  training?: Training,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Form to edit or create trainings
 */
export const TrainingForm: React.FC<TrainingFormProps> = ({ action, training, onError, onSuccess }) => {
  const [machineModule, setMachineModule] = useState<Setting>(null);
  const { handleSubmit, register, control, setValue, formState } = useForm<Training>({ defaultValues: { ...training } });
  const output = useWatch<Training>({ control });
  const { t } = useTranslation('admin');

  useEffect(() => {
    SettingAPI.get('machines_module').then(setMachineModule).catch(onError);
  }, []);

  /**
   * Callback triggered when the user validates the machine form: handle create or update
   */
  const onSubmit: SubmitHandler<Training> = (data: Training) => {
    TrainingAPI[action](data).then((res) => {
      onSuccess(t(`app.admin.training_form.${action}_success`));
      window.location.href = `/#!/trainings/${res.slug}`;
    }).catch(error => {
      onError(error);
    });
  };

  /**
   * Convert a machine to an option usable by react-select
   */
  const machineToOption = (machine: Machine): SelectOption<number> => {
    return { value: machine.id, label: machine.name };
  };

  /**
   * Asynchronously load the full list of enabled machines to display in the drop-down select field
   */
  const loadMachines = (inputValue: string, callback: (options: Array<SelectOption<number>>) => void): void => {
    MachineAPI.index({ disabled: false }).then(data => {
      callback(data.map(m => machineToOption(m)));
    }).catch(error => onError(error));
  };

  return (
    <form className="training-form" onSubmit={handleSubmit(onSubmit)}>
      <FormInput register={register} id="name"
                 formState={formState}
                 rules={{ required: true }}
                 label={t('app.admin.training_form.name')} />
      <FormImageUpload setValue={setValue}
                       register={register}
                       control={control}
                       formState={formState}
                       rules={{ required: true }}
                       id="training_image_attributes"
                       accept="image/*"
                       defaultImage={output.training_image_attributes}
                       label={t('app.admin.training_form.illustration')} />
      <FormRichText control={control}
                    id="description"
                    rules={{ required: true }}
                    label={t('app.admin.training_form.description')}
                    limit={null}
                    heading bulletList blockquote link video image />
      {machineModule?.value === 'true' && <FormMultiSelect control={control}
                                                           id="machine_ids"
                                                           formState={formState}
                                                           label={t('app.admin.training_form.associated_machines')}
                                                           loadOptions={loadMachines} />}
      <FormInput register={register}
                 type="number"
                 id="nb_total_places"
                 formState={formState}
                 rules={{ required: true }}
                 label={t('app.admin.training_form.default_seats')} />
      <FormSwitch control={control}
                  id="public_page"
                  defaultValue={true}
                  label={t('app.admin.training_form.public_page')}
                  tooltip={t('app.admin.training_form.public_help')} />
      <FormSwitch control={control}
                  id="disabled"
                  label={t('app.admin.training_form.disable_training')}
                  tooltip={t('app.admin.training_form.disabled_help')} />
      <AdvancedAccountingForm register={register} onError={onError} />
      <FabButton type="submit" className="is-info submit-btn">
        {t('app.admin.training_form.ACTION_training', { ACTION: action })}
      </FabButton>
    </form>
  );
};

const TrainingFormWrapper: React.FC<TrainingFormProps> = (props) => {
  return (
    <Loader>
      <ErrorBoundary>
        <TrainingForm {...props} />
      </ErrorBoundary>
    </Loader>
  );
};

Application.Components.component('trainingForm', react2angular(TrainingFormWrapper, ['action', 'training', 'onError', 'onSuccess']));
