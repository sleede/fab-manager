import * as React from 'react';
import { useEffect, useState } from 'react';
import { SubmitHandler, useForm, useWatch } from 'react-hook-form';
import { Machine } from '../../models/machine';
import MachineAPI from '../../api/machine';
import { useTranslation } from 'react-i18next';
import { FormInput } from '../form/form-input';
import { FormImageUpload } from '../form/form-image-upload';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { ErrorBoundary } from '../base/error-boundary';
import { FormRichText } from '../form/form-rich-text';
import { FormSwitch } from '../form/form-switch';
import { FormMultiFileUpload } from '../form/form-multi-file-upload';
import { FabButton } from '../base/fab-button';
import { AdvancedAccountingForm } from '../accounting/advanced-accounting-form';
import { FormSelect } from '../form/form-select';
import { SelectOption } from '../../models/select';
import MachineCategoryAPI from '../../api/machine-category';
import { MachineCategory } from '../../models/machine-category';

declare const Application: IApplication;

interface MachineFormProps {
  action: 'create' | 'update',
  machine?: Machine,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Form to edit or create machines
 */
export const MachineForm: React.FC<MachineFormProps> = ({ action, machine, onError, onSuccess }) => {
  const { handleSubmit, register, control, setValue, formState } = useForm<Machine>({ defaultValues: { ...machine } });
  const output = useWatch<Machine>({ control });
  const { t } = useTranslation('admin');

  const [machineCategories, setMachineCategories] = useState<Array<MachineCategory>>([]);

  // retrieve the full list of machine categories on component mount
  useEffect(() => {
    MachineCategoryAPI.index()
      .then(data => setMachineCategories(data))
      .catch(e => onError(e));
  }, []);

  /**
   * Callback triggered when the user validates the machine form: handle create or update
   */
  const onSubmit: SubmitHandler<Machine> = (data: Machine) => {
    MachineAPI[action](data).then((res) => {
      onSuccess(t(`app.admin.machine_form.${action}_success`));
      window.location.href = `/#!/machines/${res.slug}`;
    }).catch(error => {
      onError(error);
    });
  };

  /**
   * Convert all machine categories to the select format
   */
  const buildOptions = (): Array<SelectOption<number>> => {
    return machineCategories.map(t => {
      return { value: t.id, label: t.name };
    });
  };

  return (
    <form className="machine-form" onSubmit={handleSubmit(onSubmit)}>
      <FormInput register={register} id="name"
                 formState={formState}
                 rules={{ required: true }}
                 label={t('app.admin.machine_form.name')} />
      <FormImageUpload setValue={setValue}
                       register={register}
                       control={control}
                       formState={formState}
                       rules={{ required: true }}
                       id="machine_image_attributes"
                       accept="image/*"
                       defaultImage={output.machine_image_attributes}
                       label={t('app.admin.machine_form.illustration')} />
      <FormRichText control={control}
                    id="description"
                    rules={{ required: true }}
                    label={t('app.admin.machine_form.description')}
                    limit={null}
                    heading bulletList blockquote link video image />
      <FormRichText control={control}
                    id="spec"
                    rules={{ required: true }}
                    label={t('app.admin.machine_form.technical_specifications')}
                    limit={null}
                    heading bulletList blockquote link video image />
      <FormSelect options={buildOptions()}
                  control={control}
                  id="machine_category_id"
                  formState={formState}
                  label={t('app.admin.machine_form.category')} />
      <div className='form-item-header machine-files-header'>
        <p>{t('app.admin.machine_form.attached_files_pdf')}</p>
      </div>
      <FormMultiFileUpload setValue={setValue}
                           addButtonLabel={t('app.admin.machine_form.add_an_attachment')}
                           control={control}
                           accept="application/pdf"
                           register={register}
                           id="machine_files_attributes"
                           className="machine-files" />

      <FormSwitch control={control}
                  id="reservable"
                  label={t('app.admin.machine_form.reservable')}
                  tooltip={t('app.admin.machine_form.reservable_help')}
                  defaultValue={true} />
      <FormSwitch control={control}
                  id="disabled"
                  label={t('app.admin.machine_form.disable_machine')}
                  tooltip={t('app.admin.machine_form.disabled_help')} />
      <AdvancedAccountingForm register={register} onError={onError} />
      <FabButton type="submit" className="is-info submit-btn">
        {t('app.admin.machine_form.ACTION_machine', { ACTION: action })}
      </FabButton>
    </form>
  );
};

const MachineFormWrapper: React.FC<MachineFormProps> = (props) => {
  return (
    <Loader>
      <ErrorBoundary>
        <MachineForm {...props} />
      </ErrorBoundary>
    </Loader>
  );
};

Application.Components.component('machineForm', react2angular(MachineFormWrapper, ['action', 'machine', 'onError', 'onSuccess']));
