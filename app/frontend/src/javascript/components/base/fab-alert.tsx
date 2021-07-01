import React from 'react';

interface FabAlertProps {
  level: 'info' | 'warning' | 'danger',
  className?: string,
}

/**
 * This component shows a styled text paragraph, useful to display important information messages.
 */
export const FabAlert: React.FC<FabAlertProps> = ({ level, className, children }) => {
  return (
    <div className={`fab-alert fab-alert--${level} ${className || ''}`}>
      {children}
    </div>
  );
};
