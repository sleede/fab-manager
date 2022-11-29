import { PropsWithChildren, ReactNode, useEffect, useState } from 'react';
import * as React from 'react';
import { AbstractFormComponent } from '../../models/form-component';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { get as _get } from 'lodash';

export interface AbstractFormItemProps<TFieldValues> extends PropsWithChildren<AbstractFormComponent<TFieldValues>> {
  id: string,
  label?: string|ReactNode,
  ariaLabel?: string,
  ariaLabelledBy?: string,
  tooltip?: ReactNode,
  className?: string,
  disabled?: boolean|((id: string) => boolean),
  onLabelClick?: (event: React.MouseEvent<HTMLParagraphElement, MouseEvent>) => void,
  inLine?: boolean,
  containerType?: 'label' | 'div'
}

/**
 * This abstract component should not be used directly.
 * Other forms components that are intended to be used with react-hook-form must extend this component.
 */
export const AbstractFormItem = <TFieldValues extends FieldValues>({ id, label, ariaLabel, ariaLabelledBy, tooltip, className, disabled, error, warning, rules, formState, onLabelClick, inLine, containerType, children }: AbstractFormItemProps<TFieldValues>) => {
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
    `${className || ''}`,
    `${isDirty && fieldError ? 'is-incorrect' : ''}`,
    `${isDirty && warning ? 'is-warned' : ''}`,
    `${rules && rules.required ? 'is-required' : ''}`,
    `${isDisabled ? 'is-disabled' : ''}`
  ].join(' ');

  /**
   * This function is called when the label is clicked.
   * It is used to focus the input.
   */
  function handleLabelClick (event: React.MouseEvent<HTMLParagraphElement, MouseEvent>) {
    if (typeof onLabelClick === 'function') {
      onLabelClick(event);
    }
  }

  return React.createElement(containerType, { className: `form-item ${classNames}` }, (
    <>
      {(label && !inLine) && <div className='form-item-header'>
        <p onClick={handleLabelClick}>{label}</p>
        {tooltip && <div className="fab-tooltip">
          <span className="trigger"><i className="fa fa-question-circle" /></span>
          <div className="content">{tooltip}</div>
        </div>}
      </div>}

      <div className='form-item-field' aria-label={ariaLabel} aria-labelledby={ariaLabelledBy}>
        {inLine && <div className='form-item-header'><p>{label}</p>
          {tooltip && <div className="fab-tooltip">
            <span className="trigger"><i className="fa fa-question-circle" /></span>
            <div className="content">{tooltip}</div>
          </div>}
        </div>}
        {children}
      </div>
      {(isDirty && fieldError) && <div className="form-item-error">{fieldError.message}</div> }
      {(isDirty && warning) && <div className="form-item-warning">{warning.message}</div> }
    </>
  ));
};

AbstractFormItem.defaultProps = { containerType: 'label' };
