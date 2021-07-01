import React, { ReactNode } from 'react';

interface FabPopoverProps {
  title: string,
  className?: string,
  headerButton?: ReactNode,
}

/**
 * This component is a template for a popovers (bottom) that wraps the application style
 */
export const FabPopover: React.FC<FabPopoverProps> = ({ title, className, headerButton, children }) => {

  /**
   * Check if the header button should be present
   */
  const hasHeaderButton = (): boolean => {
    return !!headerButton;
  }

  return (
    <div className={`fab-popover ${className ? className : ''}`}>
      <div className="popover-title">
        <h3>{title}</h3>
        {hasHeaderButton() && headerButton}
      </div>
      <div className="popover-content">
        {children}
      </div>
    </div>
  );
}
