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
    <div className={`fab-panel ${className || ''}`}>
      {header && <div>
        <div className={`panel-header ${size}`}>
          {header}
        </div>
        <div className="panel-content">
          {children}
        </div>
      </div>}
      {!header && <div className="no-header">
        {children}
      </div>}
    </div>
  );
};
