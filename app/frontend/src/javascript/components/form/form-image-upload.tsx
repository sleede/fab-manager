import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Path, Controller } from 'react-hook-form';
import { UnpackNestedValue, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { FieldPath, FieldPathValue } from 'react-hook-form/dist/types/path';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormInput } from './form-input';
import { FormComponent, FormControlledComponent } from '../../models/form-component';
import { AbstractFormItemProps } from './abstract-form-item';
import { FabButton } from '../base/fab-button';
import noImage from '../../../../images/no_image.png';
import { Trash } from 'phosphor-react';
import { ImageType } from '../../models/file';
import FileUploadLib from '../../lib/file-upload';

interface FormImageUploadProps<TFieldValues, TContext extends object> extends FormComponent<TFieldValues>, FormControlledComponent<TFieldValues, TContext>, AbstractFormItemProps<TFieldValues> {
  setValue: UseFormSetValue<TFieldValues>,
  defaultImage?: ImageType,
  accept?: string,
  size?: 'small' | 'medium' | 'large',
  mainOption?: boolean,
  onFileChange?: (value: ImageType) => void,
  onFileRemove?: () => void,
  onFileIsMain?: (setIsMain: () => void) => void,
}

/**
 * This component allows to upload image, in forms managed by react-hook-form.
 */
export const FormImageUpload = <TFieldValues extends FieldValues, TContext extends object>({ id, label, register, control, defaultImage, className, rules, disabled, error, warning, formState, onFileChange, onFileRemove, accept, setValue, size, onFileIsMain, mainOption = false }: FormImageUploadProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('shared');

  const [file, setFile] = useState<ImageType>(defaultImage);
  const [image, setImage] = useState<string | ArrayBuffer>(defaultImage.attachment_url);

  useEffect(() => {
    setFile(defaultImage);
  }, [defaultImage]);

  /**
   * Check if image is selected
   */
  const hasImage = (): boolean => {
    return FileUploadLib.hasFile(file);
  };

  /**
   * Callback triggered when the user has ended its selection of a file (or when the selection has been cancelled).
   */
  function onFileSelected (event: React.ChangeEvent<HTMLInputElement>) {
    const f = event.target?.files[0];
    if (f) {
      const reader = new FileReader();
      reader.onload = (): void => {
        setImage(reader.result);
      };
      reader.readAsDataURL(f);
      setFile({
        ...file,
        attachment_name: f.name
      });
      setValue(
        `${id}.attachment_name` as Path<TFieldValues>,
        f.name as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
      );
      setValue(
        `${id}._destroy` as Path<TFieldValues>,
        false as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
      );
      if (typeof onFileChange === 'function') {
        onFileChange({ attachment_name: f.name });
      }
    }
  }

  /**
   * Callback triggered when the user clicks on the delete button.
   */
  function onRemoveFile () {
    FileUploadLib.onRemoveFile(file, id, setFile, setValue, onFileRemove);
  }

  /**
   * Returns placeholder text
   */
  const placeholder = (): string => hasImage() ? t('app.shared.form_image_upload.edit') : t('app.shared.form_image_upload.browse');

  // Compose classnames from props
  const classNames = [
    `${className || ''}`
  ].join(' ');

  return (
    <div className={`form-image-upload form-image-upload--${size} ${label ? 'with-label' : ''} ${classNames}`}>
      <div className={`image image--${size}`}>
        <img src={hasImage() ? image : noImage} alt={file?.attachment_name || 'no image'} onError={({ currentTarget }) => {
          currentTarget.onerror = null;
          currentTarget.src = noImage;
        }} />
      </div>
      <div className="actions">
        {mainOption &&
          <label className='fab-button'>
            {t('app.shared.form_image_upload.main_image')}
            <Controller name={`${id}.is_main` as FieldPath<TFieldValues>}
              control={control}
              render={({ field: { onChange, value } }) =>
                <input id={`${id}.is_main`}
                  type="radio"
                  checked={value}
                  onChange={() => { onFileIsMain(onChange); }} />
              } />
          </label>
        }
        <FormInput className="image-file-input"
                   type="file"
                   accept={accept}
                   register={register}
                   label={label}
                   formState={formState}
                   rules={rules}
                   disabled={disabled}
                   error={error}
                   warning={warning}
                   id={`${id}.attachment_files`}
                   onChange={onFileSelected}
                   placeholder={placeholder()}/>
        {hasImage() && <FabButton onClick={onRemoveFile} icon={<Trash size={20} weight="fill" />} className="is-main" />}
      </div>
    </div>
  );
};

FormImageUpload.defaultProps = {
  size: 'medium'
};
