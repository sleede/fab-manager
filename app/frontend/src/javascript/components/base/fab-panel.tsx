import { ReactNode } from 'react';
import * as React from 'react';

interface FabPanelProps {
  className?: string,
  header?: ReactNode,
  size?: 'small' | 'normal'
}

/**
 * Simple styled panel component
 */
export const FabPanel: React.FC<FabPanelProps> = ({ className, header, size, children }) => {
  return (
    <div className={`fab-panel ${className || ''} ${!header ? 'no-header' : ''}`}>
      {header && <>
        <div className={`panel-header ${size}`}>
          {header}
        </div>
        <div className="panel-content">
          {children}
        </div>
      </>}
      {!header && <>{ children }</>}
    </div>
  );
};
