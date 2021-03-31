/**
 * This component is a template for an input component that wraps the application style
 */

import React, { BaseSyntheticEvent, ReactNode, useCallback, useEffect, useState } from 'react';
import { debounce as _debounce } from 'lodash';
import SettingAPI from '../api/setting';
import { SettingName } from '../models/setting';
import { loadStripe } from '@stripe/stripe-js';

interface FabInputProps {
  id: string,
  onChange?: (value: any) => void,
  value: any,
  icon?: ReactNode,
  addOn?: ReactNode,
  addOnClassName?: string,
  className?: string,
  disabled?: boolean,
  required?: boolean,
  debounce?: number,
  type?: 'text' | 'date' | 'password' | 'url' | 'time' | 'tel' | 'search' | 'number' | 'month' | 'email' | 'datetime-local' | 'week',
}

export const FabInput: React.FC<FabInputProps> = ({ id, onChange, value, icon, className, disabled, type, required, debounce, addOn, addOnClassName }) => {
  const [inputValue, setInputValue] = useState<any>(value);

  useEffect(() => {
    setInputValue(value);
    if (value) {
      onChange(value);
    }
  }, [value]);

  /**
   * Check if the current component was provided an icon to display
   */
  const hasIcon = (): boolean => {
    return !!icon;
  }

  /**
   * Check if the current component was provided an add-on element to display, at the end of the input
   */
  const hasAddOn = (): boolean => {
    return !!addOn;
  }

  /**
   * Debounced (ie. temporised) version of the 'on change' callback.
   */
  const handler = useCallback(_debounce(onChange, debounce), []);

  /**
   * Handle the action of the button
   */
  const handleChange = (e: BaseSyntheticEvent): void => {
    const newValue = e.target.value;
    setInputValue(newValue);
    if (typeof onChange === 'function') {
      if (debounce) {
        handler(newValue);
      } else {
        onChange(newValue);
      }
    }
  }

  return (
    <div className={`fab-input ${className ? className : ''}`}>
      {hasIcon() && <span className="fab-input--icon">{icon}</span>}
      <input id={id} type={type} className="fab-input--input" value={inputValue} onChange={handleChange} disabled={disabled} required={required} />
      {hasAddOn() && <span className={`fab-input--addon ${addOnClassName ?  addOnClassName : ''}`}>{addOn}</span>}
    </div>
  );
}

FabInput.defaultProps = { type: 'text', debounce: 0 };

