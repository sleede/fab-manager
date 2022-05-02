import React from 'react';

import noAvatar from '../../../../images/no_avatar.png';
import { FabButton } from '../base/fab-button';
import { Path, UseFormRegister } from 'react-hook-form';
import { UnpackNestedValue, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { FieldPathValue } from 'react-hook-form/dist/types/path';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormInput } from '../form/form-input';

interface AvatarInputProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  setValue: UseFormSetValue<TFieldValues>,
}

/**
 * This component allows to set the user's avatar, in forms managed by react-hook-form.
 */
export const AvatarInput: React.FC = <TFieldValues extends FieldValues>({ register, setValue }: AvatarInputProps<FieldValues>) => {
  /**
   * Check if the provided user has a configured avatar
   */
  const hasAvatar = (): boolean => {
    return !!user?.profile_attributes?.user_avatar_attributes?.attachment_url;
  };

  const onAddAvatar = (): void => {
    setValue(
      'profile_attributes.user_avatar_attributes._destroy' as Path<TFieldValues>,
      false as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
    );
  };

  return (
    <div className={`avatar ${className || ''}`}>
      {!hasAvatar() && <img src={noAvatar} alt="avatar placeholder"/>}
      {hasAvatar() && <img src={user.profile_attributes.user_avatar_attributes.attachment_url} alt="user's avatar"/>}
      {mode === 'edit' && <div className="edition">
        <FabButton onClick={onAddAvatar}>
          {!hasAvatar() && <span>Add an avatar</span>}
          {hasAvatar() && <span>Change</span>}
          <FormInput type="file" accept="image/*" register={register} id="profile_attributes.user_avatar_attributes.attachment"/>
        </FabButton>
        {hasAvatar() && <FabButton>Remove</FabButton>}
      </div>}
    </div>
  );
};

Avatar.defaultProps = {
  mode: 'display'
};
