import { useState } from 'react';
import * as React from 'react';

import { FabButton } from '../base/fab-button';
import { Path, UseFormRegister } from 'react-hook-form';
import { UnpackNestedValue, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { FieldPathValue } from 'react-hook-form/dist/types/path';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormInput } from '../form/form-input';
import { Avatar } from './avatar';
import { useTranslation } from 'react-i18next';

interface AvatarInputProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  setValue: UseFormSetValue<TFieldValues>,
  currentAvatar: string,
  userName: string,
  size?: 'small' | 'large'
}

/**
 * This component allows to set the user's avatar, in forms managed by react-hook-form.
 */
export const AvatarInput = <TFieldValues extends FieldValues>({ currentAvatar, userName, register, setValue, size }: AvatarInputProps<TFieldValues>) => {
  const { t } = useTranslation('shared');

  const [avatar, setAvatar] = useState<string|ArrayBuffer>(currentAvatar);
  /**
   * Check if the provided user has a configured avatar
   */
  const hasAvatar = (): boolean => {
    return !!avatar;
  };

  /**
   * Callback triggered when the user starts to select a file.
   */
  const onAddAvatar = (): void => {
    setValue(
      'profile_attributes.user_avatar_attributes._destroy' as Path<TFieldValues>,
      false as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
    );
  };

  /**
   * Callback triggered when the user clicks on the delete button.
   */
  function onRemoveAvatar () {
    setValue(
      'profile_attributes.user_avatar_attributes._destroy' as Path<TFieldValues>,
      true as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
    );
    setAvatar(null);
  }

  /**
   * Callback triggered when the user has ended its selection of a file (or when the selection has been cancelled).
   */
  function onFileSelected (event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target?.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (): void => {
        setAvatar(reader.result);
      };
      reader.readAsDataURL(file);
    } else {
      setAvatar(null);
    }
  }

  return (
    <div className={`avatar-input avatar-input--${size}`}>
      <Avatar avatar={avatar} userName={userName} size="large" />
      <div className="buttons">
        <FabButton onClick={onAddAvatar} className="select-button">
          {!hasAvatar() && <span>{t('app.shared.avatar_input.add_an_avatar')}</span>}
          {hasAvatar() && <span>{t('app.shared.avatar_input.change')}</span>}
          <FormInput className="avatar-file-input"
                     type="file"
                     accept="image/*"
                     register={register}
                     id="profile_attributes.user_avatar_attributes.attachment_files"
                     onChange={onFileSelected}/>
        </FabButton>
        {hasAvatar() && <FabButton onClick={onRemoveAvatar} icon={<i className="fa fa-trash-o"/>} className="delete-avatar" />}
        <FormInput register={register}
                   id="profile_attributes.user_avatar_attributes.id"
                   type="hidden" />
      </div>
    </div>
  );
};
