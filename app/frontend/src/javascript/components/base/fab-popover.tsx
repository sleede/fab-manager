import { ReactNode } from 'react';
import * as React from 'react';

interface FabPopoverProps {
  title: string,
  className?: string,
  headerButton?: ReactNode,
  position?: 'bottom' | 'right' | 'left'
}

/**
 * This component is a template for a popovers (bottom) that wraps the application style.
 * Please note that the parent element must be set `position: relative;` otherwise the popover won't be placed correctly.
 */
export const FabPopover: React.FC<FabPopoverProps> = ({ title, className, headerButton, position = 'bottom', children }) => {
  /**
   * Check if the header button should be present
   */
  const hasHeaderButton = (): boolean => {
    return !!headerButton;
  };

  return (
    <div className={`fab-popover fab-popover__${position} ${className || ''}`}>
      <div className="popover-title">
        <h3>{title}</h3>
        {hasHeaderButton() && headerButton}
      </div>
      <div className="popover-content">
        {children}
      </div>
    </div>
  );
};
