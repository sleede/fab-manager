import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Path } from 'react-hook-form';
import { UnpackNestedValue, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { FieldPathValue } from 'react-hook-form/dist/types/path';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormInput } from '../form/form-input';
import { FormComponent } from '../../models/form-component';
import { AbstractFormItemProps } from './abstract-form-item';

export interface FileType {
  id?: number,
  attachment_name?: string,
  attachment_url?: string
}

interface FormFileUploadProps<TFieldValues> extends FormComponent<TFieldValues>, AbstractFormItemProps<TFieldValues> {
  setValue: UseFormSetValue<TFieldValues>,
  defaultFile?: FileType,
  accept?: string,
  onFileChange?: (value: FileType) => void,
  onFileRemove?: () => void,
}

/**
 * This component allows to upload file, in forms managed by react-hook-form.
 */
export const FormFileUpload = <TFieldValues extends FieldValues>({ id, register, defaultFile, className, rules, disabled, error, warning, formState, onFileChange, onFileRemove, accept, setValue }: FormFileUploadProps<TFieldValues>) => {
  const { t } = useTranslation('shared');

  const [file, setFile] = useState<FileType>(defaultFile);

  /**
   * Check if file is selected
   */
  const hasFile = (): boolean => {
    return !!file?.attachment_name;
  };

  /**
   * Callback triggered when the user has ended its selection of a file (or when the selection has been cancelled).
   */
  function onFileSelected (event: React.ChangeEvent<HTMLInputElement>) {
    const f = event.target?.files[0];
    if (f) {
      setFile({
        attachment_name: f.name
      });
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

  // Compose classnames from props
  const classNames = [
    `${className || ''}`
  ].join(' ');

  return (
    <div className={`form-file-upload fileinput ${classNames}`}>
      <div className="filename-container">
        {hasFile() && (
          <div>
            <i className="fa fa-file fileinput-exists" />
            <span className="fileinput-filename">
              {file.attachment_name}
            </span>
          </div>
        )}
        {file?.id && file?.attachment_url && (
          <a href={file.attachment_url}
            target="_blank"
            className="file-download"
            rel="noreferrer">
            <i className="fa fa-download"/>
          </a>
        )}
      </div>
      <span className="fileinput-button">
        {!hasFile() && (
          <span className="fileinput-new">{t('app.shared.form_file_upload.browse')}</span>
        )}
        {hasFile() && (
          <span className="fileinput-exists">{t('app.shared.form_file_upload.edit')}</span>
        )}
        <FormInput type="file"
                   accept={accept}
                   register={register}
                   formState={formState}
                   rules={rules}
                   disabled={disabled}
                   error={error}
                   warning={warning}
                   id={`${id}[attachment_files]`}
                   onChange={onFileSelected}/>
      </span>
      {hasFile() && (
        <a className="fileinput-exists fileinput-delete" onClick={onRemoveFile}>
          <i className="fa fa-trash-o"></i>
        </a>
      )}
    </div>
  );
};
