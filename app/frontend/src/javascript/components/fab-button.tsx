/**
 * This component is a template for a clickable button that wraps the application style
 */

import React, { ReactNode, SyntheticEvent } from 'react';

interface FabButtonProps {
  onClick?: (event: SyntheticEvent) => void,
  icon?: ReactNode,
  className?: string,
  disabled?: boolean,
}


export const FabButton: React.FC<FabButtonProps> = ({ onClick, icon, className, disabled, children }) => {
  /**
   * Check if the current component was provided an icon to display
   */
  const hasIcon = (): boolean => {
    return !!icon;
  }

  /**
   * Handle the action of the button
   */
  const handleClick = (e: SyntheticEvent): void => {
    if (typeof onClick === 'function') {
      onClick(e);
    }
  }

  return (
    <button onClick={handleClick} disabled={disabled} className={`fab-button ${className ? className : ''}`}>
      {hasIcon() && <span className="fab-button--icon">{icon}</span>}
      {children}
    </button>
  );
}

