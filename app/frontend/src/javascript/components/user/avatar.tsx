import React from 'react';

import noAvatar from '../../../../images/no_avatar.png';

interface AvatarProps {
  avatar?: string | ArrayBuffer,
  userName: string,
  className?: string,
  size?: 'small' | 'large',
}

/**
 * This component renders the user-profile's picture or a placeholder.
 */
export const Avatar: React.FC<AvatarProps> = ({ avatar, className, userName, size }) => {
  return (
    <div className={`avatar avatar--${size} ${className || ''}`}>
      <img src={avatar || noAvatar} alt={userName} />
    </div>
  );
};

Avatar.defaultProps = {
  size: 'small'
};
