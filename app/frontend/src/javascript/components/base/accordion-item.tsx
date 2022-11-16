import { useState, useEffect } from 'react';
import * as React from 'react';
import { CaretDown } from 'phosphor-react';

interface AccordionItemProps {
  isOpen: boolean,
  onChange: (id: number, isOpen: boolean) => void,
  id: number,
  label: string
}

/**
 * Renders an accordion item
 */
export const AccordionItem: React.FC<AccordionItemProps> = ({ isOpen, onChange, id, label, children }) => {
  const [state, setState] = useState(isOpen);

  useEffect(() => {
    onChange(id, state);
  }, [state]);

  return (
    <div id={id.toString()} className={`accordion-item ${state ? '' : 'collapsed'}`}>
      <header onClick={() => setState(!state)}>
        {label}
        <CaretDown size={16} weight="bold" />
      </header>
      {children}
    </div>
  );
};
