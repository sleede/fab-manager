import React from 'react';
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
    <form className="space-form" onSubmit={handleSubmit(onSubmit)}>
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
                    label={t('app.admin.space_form.description')}
                    limit={null}
                    heading bulletList blockquote link video image />
      <FormRichText control={control}
                    id="characteristics"
                    label={t('app.admin.space_form.characteristics')}
                    limit={null}
                    heading bulletList blockquote link video image />

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

      <FormSwitch control={control}
                  id="disabled"
                  label={t('app.admin.space_form.disable_space')}
                  tooltip={t('app.admin.space_form.disabled_help')} />
      <FabButton type="submit" className="is-info submit-btn">
        {t('app.admin.space_form.ACTION_space', { ACTION: action })}
      </FabButton>
    </form>
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
