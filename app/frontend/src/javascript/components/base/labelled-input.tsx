import React, { BaseSyntheticEvent, ReactNode } from 'react';

interface LabelledInputProps {
  id: string,
  type?: 'text' | 'date' | 'password' | 'url' | 'time' | 'tel' | 'search' | 'number' | 'month' | 'email' | 'datetime-local' | 'week',
  label: string | ReactNode,
  value: any,
  onChange: (event: BaseSyntheticEvent) => void
}

/**
 * This component shows input field with its label, styled
 */
export const LabelledInput: React.FC<LabelledInputProps> = ({ id, type, label, value, onChange }) => {
  return (
    <div className="input-with-label">
      <label className="label" htmlFor={id}>{label}</label>
      <input className="input" id={id} type={type} value={value} onChange={onChange} />
    </div>
  );
}
