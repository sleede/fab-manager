import React from 'react';
import { User } from '../../models/user';

import noAvatar from '../../../../images/no_avatar.png';

interface AvatarProps {
  user: User,
  className?: string,
}

/**
 * This component renders the user-profile's picture or a placeholder
 */
export const Avatar: React.FC<AvatarProps> = ({ user, className }) => {
  /**
   * Check if the provided user has a configured avatar
   */
  const hasAvatar = (): boolean => {
    return !!user?.profile?.user_avatar?.attachment_url;
  };

  return (
    <div className={`avatar ${className || ''}`}>
      {!hasAvatar() && <img src={noAvatar} alt="avatar placeholder"/>}
      {hasAvatar() && <img src={user.profile.user_avatar.attachment_url} alt="user's avatar"/>}
    </div>
  );
};
