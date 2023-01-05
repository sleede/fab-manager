import { BaseSyntheticEvent, ReactNode } from 'react';
import * as React from 'react';

type inputType = string|number|readonly string [];

interface LabelledInputProps {
  id: string,
  type?: 'text' | 'date' | 'password' | 'url' | 'time' | 'tel' | 'search' | 'number' | 'month' | 'email' | 'datetime-local' | 'week',
  label: string | ReactNode,
  value: inputType,
  onChange: (event: BaseSyntheticEvent) => void
}

/**
 * This component shows input field with its label, styled
 */
export const LabelledInput: React.FC<LabelledInputProps> = ({ id, type, label, value, onChange }) => {
  return (
    <div className="labelled-input">
      <label htmlFor={id}>{label}</label>
      <input id={id} type={type} value={value} onChange={onChange} />
    </div>
  );
};
