import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Path } from 'react-hook-form';
import { UnpackNestedValue, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { FieldPathValue } from 'react-hook-form/dist/types/path';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormInput } from './form-input';
import { FormComponent } from '../../models/form-component';
import { AbstractFormItemProps } from './abstract-form-item';
import { FabButton } from '../base/fab-button';
import { FilePdf, Trash } from 'phosphor-react';
import { FileType } from '../../models/file';
import FileUploadLib from '../../lib/file-upload';

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
export const FormFileUpload = <TFieldValues extends FieldValues>({ id, label, register, defaultFile, className, rules, disabled, error, warning, formState, onFileChange, onFileRemove, accept, setValue }: FormFileUploadProps<TFieldValues>) => {
  const { t } = useTranslation('shared');

  const [file, setFile] = useState<FileType>(defaultFile);

  /**
   * Check if file is selected
   */
  const hasFile = (): boolean => {
    return FileUploadLib.hasFile(file);
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

  // Compose classnames from props
  const classNames = [
    `${className || ''}`
  ].join(' ');

  /**
   * Returns placeholder text
   */
  const placeholder = (): string => hasFile() ? t('app.shared.form_file_upload.edit') : t('app.shared.form_file_upload.browse');

  return (
    <div className={`form-file-upload ${label ? 'with-label' : ''} ${classNames}`}>
      {hasFile() && (
        <span>{file.attachment_name}</span>
      )}
      <div className="actions">
        {file?.id && file?.attachment_url && (
          <a href={file.attachment_url}
            target="_blank"
            className="fab-button"
            rel="noreferrer">
            <FilePdf size={24} />
          </a>
        )}
        <FormInput type="file"
                    className="image-file-input"
                    accept={accept}
                    register={register}
                    label={label}
                    formState={formState}
                    rules={rules}
                    disabled={disabled}
                    error={error}
                    warning={warning}
                    id={`${id}[attachment_files]`}
                    onChange={onFileSelected}
                    placeholder={placeholder()}/>
        {hasFile() &&
          <FabButton onClick={onRemoveFile} icon={<Trash size={20} weight="fill" />} className="is-main" />
        }
      </div>
    </div>
  );
};
