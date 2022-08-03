import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Path } from 'react-hook-form';
import { UnpackNestedValue, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { FieldPathValue } from 'react-hook-form/dist/types/path';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormInput } from '../form/form-input';
import { FormComponent } from '../../models/form-component';
import { AbstractFormItemProps } from './abstract-form-item';
import { FabButton } from '../base/fab-button';
import noAvatar from '../../../../images/no_avatar.png';

export interface ImageType {
  id?: number,
  attachment_name?: string,
  attachment_url?: string,
  is_main?: boolean
}

interface FormImageUploadProps<TFieldValues> extends FormComponent<TFieldValues>, AbstractFormItemProps<TFieldValues> {
  setValue: UseFormSetValue<TFieldValues>,
  defaultImage?: ImageType,
  accept?: string,
  size?: 'small' | 'large'
  mainOption?: boolean,
  onFileChange?: (value: ImageType) => void,
  onFileRemove?: () => void,
  onFileIsMain?: () => void,
}

/**
 * This component allows to upload image, in forms managed by react-hook-form.
 */
export const FormImageUpload = <TFieldValues extends FieldValues>({ id, register, defaultImage, className, rules, disabled, error, warning, formState, onFileChange, onFileRemove, accept, setValue, size, onFileIsMain, mainOption = false }: FormImageUploadProps<TFieldValues>) => {
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
    return !!file?.attachment_name;
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
        `${id}[attachment_name]` as Path<TFieldValues>,
        f.name as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
      );
      setValue(
        `${id}[_destroy]` as Path<TFieldValues>,
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
    if (file?.id) {
      setValue(
        `${id}[_destroy]` as Path<TFieldValues>,
        true as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
      );
    }
    setValue(
      `${id}[attachment_files]` as Path<TFieldValues>,
      null as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
    );
    setFile(null);
    if (typeof onFileRemove === 'function') {
      onFileRemove();
    }
  }

  /**
   * Callback triggered when the user set the image is main
   */
  function setMainImage () {
    setValue(
      `${id}[is_main]` as Path<TFieldValues>,
      true as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
    );
    onFileIsMain();
  }

  // Compose classnames from props
  const classNames = [
    `${className || ''}`
  ].join(' ');

  return (
    <div className={`form-image-upload form-image-upload--${size} ${classNames}`}>
      <div className={`image image--${size}`}>
        <img src={image || noAvatar} />
      </div>
      <div className="buttons">
        <FabButton className="select-button">
          {!hasImage() && <span>{t('app.shared.form_image_upload.browse')}</span>}
          {hasImage() && <span>{t('app.shared.form_image_upload.edit')}</span>}
          <FormInput className="image-file-input"
                     type="file"
                     accept={accept}
                     register={register}
                     formState={formState}
                     rules={rules}
                     disabled={disabled}
                     error={error}
                     warning={warning}
                     id={`${id}[attachment_files]`}
                     onChange={onFileSelected}/>
        </FabButton>
        {hasImage() && <FabButton onClick={onRemoveFile} icon={<i className="fa fa-trash-o"/>} className="delete-image" />}
      </div>
      {mainOption &&
        <div>
          <input type="radio" checked={!!file?.is_main} onChange={setMainImage} />
          <label>{t('app.shared.form_image_upload.main_image')}</label>
        </div>
      }
    </div>
  );
};
