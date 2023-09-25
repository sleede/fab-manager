import * as React from 'react';
import { useEffect, useState } from 'react';
import { SubmitHandler, useForm, useWatch } from 'react-hook-form';
import SpaceAPI from '../../api/space';
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
import { Space } from '../../models/space';
import { Machine } from '../../models/machine';
import { AdvancedAccountingForm } from '../accounting/advanced-accounting-form';
import SettingAPI from '../../api/setting';
import { FabAlert } from '../base/fab-alert';
import MachineAPI from '../../api/machine';
import { FormMultiSelect } from '../form/form-multi-select';
import { SelectOption } from '../../models/select';

declare const Application: IApplication;

interface SpaceFormProps {
  action: 'create' | 'update',
  space?: Space,
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
}

/**
 * Form to edit or create spaces
 */
export const SpaceForm: React.FC<SpaceFormProps> = ({ action, space, onError, onSuccess }) => {
  const { handleSubmit, register, control, setValue, formState } = useForm<Space>({ defaultValues: { ...space } });
  const output = useWatch<Space>({ control });
  const { t } = useTranslation('admin');

  const [isActiveAccounting, setIsActiveAccounting] = useState<boolean>(false);

  useEffect(() => {
    SettingAPI.get('advanced_accounting').then(res => setIsActiveAccounting(res.value === 'true')).catch(onError);
  }, []);

  /**
   * Asynchronously load the full list of machines to display in the drop-down select field
   */
  const loadMachines = (inputValue: string, callback: (options: Array<SelectOption<number>>) => void): void => {
    MachineAPI.index().then(data => {
      callback(data.map(m => machineToOption(m)));
    }).catch(error => onError(error));
  };

  /**
   * Convert a machine to an option usable by react-select
   */
  const machineToOption = (machine: Machine): SelectOption<number> => {
    return { value: machine.id, label: machine.name };
  };

  /**
 * Asynchronously load the full list of spaces to display in the drop-down select field
 */
  const loadSpaces = (inputValue: string, callback: (options: Array<SelectOption<number>>) => void): void => {
    SpaceAPI.index().then(data => {
      if (space) {
        data = data.filter((d) => d.id !== space.id);
      }
      callback(data.map(m => spaceToOption(m)));
    }).catch(error => onError(error));
  };

  /**
   * Convert a space to an option usable by react-select
   */
  const spaceToOption = (space: Space): SelectOption<number> => {
    return { value: space.id, label: space.name };
  };

  /**
   * Callback triggered when the user validates the machine form: handle create or update
   */
  const onSubmit: SubmitHandler<Space> = (data: Space) => {
    SpaceAPI[action](data).then((res) => {
      onSuccess(t(`app.admin.space_form.${action}_success`));
      window.location.href = `/#!/spaces/${res.slug}`;
    }).catch(error => {
      onError(error);
    });
  };

  return (
    <div className="space-form">
      <header>
        <h2>{t('app.admin.space_form.ACTION_title', { ACTION: action })}</h2>
        <FabButton onClick={handleSubmit(onSubmit)} className="fab-button save-btn is-main">
          {t('app.admin.space_form.save')}
        </FabButton>
      </header>
      <form className="space-form-content" onSubmit={handleSubmit(onSubmit)}>
        {action === 'create' &&
          <FabAlert level='warning'>
            {t('app.admin.space_form.watch_out_when_creating_a_new_space_its_prices_are_initialized_at_0_for_all_subscriptions')} {t('app.admin.space_form.consider_changing_its_prices_before_creating_any_reservation_slot')}
          </FabAlert>
        }
        <section>
          <header>
            <p className="title">{t('app.admin.space_form.description')}</p>
          </header>
          <div className="content">
            <FormInput register={register} id="name"
                      formState={formState}
                      rules={{ required: true }}
                        label={t('app.admin.space_form.name')} />
            <FormImageUpload setValue={setValue}
                            register={register}
                            control={control}
                            formState={formState}
                            rules={{ required: true }}
                            id="space_image_attributes"
                            accept="image/*"
                            defaultImage={output.space_image_attributes}
                              label={t('app.admin.space_form.illustration')} />
            <FormInput register={register}
                      type="number"
                      id="default_places"
                      formState={formState}
                      rules={{ required: true }}
                        label={t('app.admin.space_form.default_seats')} />
            <FormRichText control={control}
                          id="description"
                          rules={{ required: true }}
                          formState={formState}
                          label={t('app.admin.space_form.description')}
                          limit={null}
                          heading bulletList blockquote link video image />
            <FormRichText control={control}
                          id="characteristics"
                          label={t('app.admin.space_form.characteristics')}
                          limit={null}
                          heading bulletList link />
          </div>
        </section>

        <section>
          <header>
            <p className="title">
              {t('app.admin.space_form.associated_objects')}
            </p>
            <p className="description">
              {t('app.admin.space_form.associated_objects_warning')}
            </p>
          </header>
          <div className="content">
            <FormMultiSelect control={control}
                             id="child_ids"
                             formState={formState}
                             label={t('app.admin.space_form.children_spaces')}
                             loadOptions={loadSpaces} />
            <FormMultiSelect control={control}
                             id="machine_ids"
                             formState={formState}
                             label={t('app.admin.space_form.associated_machines')}
                             loadOptions={loadMachines} />
          </div>
        </section>

        <section>
          <header>
            <p className="title">{t('app.admin.space_form.attachments')}</p>
          </header>
          <div className="content">
            <div className='form-item-header space-files-header'>
              <p>{t('app.admin.space_form.attached_files_pdf')}</p>
            </div>
            <FormMultiFileUpload setValue={setValue}
                                  addButtonLabel={t('app.admin.space_form.add_an_attachment')}
                                  control={control}
                                  accept="application/pdf"
                                  register={register}
                                  id="space_files_attributes"
                                  className="space-files" />
          </div>
        </section>

        <section>
          <header>
            <p className="title">{t('app.admin.space_form.settings')}</p>
          </header>
          <div className="content">
            <FormSwitch control={control}
                        id="disabled"
                        label={t('app.admin.space_form.disable_space')}
                        tooltip={t('app.admin.space_form.disabled_help')} />
          </div>
        </section>

        {isActiveAccounting &&
          <section>
            <AdvancedAccountingForm register={register} onError={onError} />
          </section>
        }
      </form>
    </div>
  );
};

const SpaceFormWrapper: React.FC<SpaceFormProps> = (props) => {
  return (
    <Loader>
      <ErrorBoundary>
        <SpaceForm {...props} />
      </ErrorBoundary>
    </Loader>
  );
};

Application.Components.component('spaceForm', react2angular(SpaceFormWrapper, ['action', 'space', 'onError', 'onSuccess']));
