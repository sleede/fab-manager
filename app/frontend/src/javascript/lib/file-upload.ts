import { Path } from 'react-hook-form';
import { UnpackNestedValue, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { FieldPathValue } from 'react-hook-form/dist/types/path';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FileType } from '../models/file';
import { Dispatch, SetStateAction } from 'react';

export default class FileUploadLib {
  public static onRemoveFile<TFieldValues extends FieldValues> (file: FileType, id: string, setFile: Dispatch<SetStateAction<FileType>>, setValue: UseFormSetValue<TFieldValues>, onFileRemove: () => void) {
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

  public static hasFile (file: FileType): boolean {
    return !!file?.attachment_name;
  }
}
