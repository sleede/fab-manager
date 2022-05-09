import React, { PropsWithChildren, ReactNode, useEffect, useState } from 'react';
import { AbstractFormComponent } from '../../models/form-component';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { get as _get } from 'lodash';

export interface AbstractFormItemProps<TFieldValues> extends PropsWithChildren<AbstractFormComponent<TFieldValues>> {
  id: string,
  label?: string|ReactNode,
  tooltip?: ReactNode,
  className?: string,
  disabled?: boolean|((id: string) => boolean),
  readOnly?: boolean
  onLabelClick?: (event: React.MouseEvent<HTMLLabelElement, MouseEvent>) => void,
}

/**
 * This abstract component should not be used directly.
 * Other forms components that are intended to be used with react-hook-form must extend this component.
 */
export const AbstractFormItem = <TFieldValues extends FieldValues>({ id, label, tooltip, className, disabled, readOnly, error, warning, rules, formState, onLabelClick, children }: AbstractFormItemProps<TFieldValues>) => {
  const [isDirty, setIsDirty] = useState<boolean>(false);
  const [fieldError, setFieldError] = useState<{ message: string }>(error);
  const [isDisabled, setIsDisabled] = useState<boolean>(false);

  useEffect(() => {
    setIsDirty(_get(formState?.dirtyFields, id));
    setFieldError(_get(formState?.errors, id));
  }, [formState]);

  useEffect(() => {
    setFieldError(error);
  }, [error]);

  useEffect(() => {
    if (typeof disabled === 'function') {
      setIsDisabled(disabled(id));
    } else {
      setIsDisabled(disabled);
    }
  }, [disabled]);

  // Compose classnames from props
  const classNames = [
    'form-item',
    `${className || ''}`,
    `${isDirty && fieldError ? 'is-incorrect' : ''}`,
    `${isDirty && warning ? 'is-warned' : ''}`,
    `${rules && rules.required ? 'is-required' : ''}`,
    `${readOnly ? 'is-readonly' : ''}`,
    `${isDisabled ? 'is-disabled' : ''}`
  ].join(' ');

  /**
   * This function is called when the label is clicked.
   * It is used to focus the input.
   */
  function handleLabelClick (event: React.MouseEvent<HTMLLabelElement, MouseEvent>) {
    if (typeof onLabelClick === 'function') {
      onLabelClick(event);
    }
  }

  return (
    <label className={classNames} onClick={handleLabelClick}>
      {label && <div className='form-item-header'>
        <p>{label}</p>
        {tooltip && <div className="item-tooltip">
          <span className="trigger"><i className="fa fa-question-circle" /></span>
          <div className="content">{tooltip}</div>
        </div>}
      </div>}
      <div className='form-item-field'>
        {children}
      </div>
      {(isDirty && fieldError) && <div className="form-item-error">{fieldError.message}</div> }
      {(isDirty && warning) && <div className="form-item-warning">{warning.message}</div> }
    </label>
  );
};
