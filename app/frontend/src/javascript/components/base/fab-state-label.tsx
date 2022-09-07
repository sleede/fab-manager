import React from 'react';

interface FabStateLabelProps {
  status?: string,
  background?: boolean
}

/**
 * Render a label preceded by a bot
 */
export const FabStateLabel: React.FC<FabStateLabelProps> = ({ status, background, children }) => {
  console.log('status: ', status);
  return (
    <span className={`fab-state-label ${status !== undefined ? status : ''} ${background ? 'bg' : ''}`}>
      {children}
    </span>
  );
};
