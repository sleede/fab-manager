import React, { useEffect } from 'react';
import { FormControlledComponent } from '../../models/form-component';
import { AbstractFormItem, AbstractFormItemProps } from './abstract-form-item';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import FabTextEditor, { FabTextEditorRef } from '../base/text-editor/fab-text-editor';
import { Controller, Path } from 'react-hook-form';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { FieldPathValue, UnpackNestedValue } from 'react-hook-form/dist/types';

interface FormRichTextProps<TFieldValues, TContext extends object> extends FormControlledComponent<TFieldValues, TContext>, AbstractFormItemProps<TFieldValues> {
  valueDefault?: string,
  limit?: number,
  heading?: boolean,
  bulletList?: boolean,
  blockquote?: boolean,
  link?: boolean,
  video?: boolean,
  image?: boolean
}

/**
 * This component is a rich-text editor to use with react-hook-form.
 */
export const FormRichText = <TFieldValues extends FieldValues, TContext extends object>({ id, label, tooltip, className, control, valueDefault, error, warning, rules, disabled = false, formState, limit, heading, bulletList, blockquote, video, image, link }: FormRichTextProps<TFieldValues, TContext>) => {
  const textEditorRef = React.useRef<FabTextEditorRef>();
  const [isDisabled, setIsDisabled] = React.useState<boolean>(false);

  useEffect(() => {
    if (typeof disabled === 'function') {
      setIsDisabled(disabled(id));
    } else {
      setIsDisabled(disabled);
    }
  }, [disabled]);

  /**
   * Callback triggered when the user clicks to get the focus on the editor.
   * We do not want the default behavior (focus the first child, which is the Bold button)
   * but we want to focus the text edition area.
   */
  function focusTextEditor (event: React.MouseEvent<HTMLParagraphElement, MouseEvent>) {
    event.preventDefault();
    textEditorRef.current.focus();
  }

  return (
    <AbstractFormItem id={id} label={label} tooltip={tooltip}
                      containerType={'div'}
                      className={`form-rich-text ${className || ''}`}
                      error={error} warning={warning} rules={rules}
                      disabled={disabled} formState={formState} onLabelClick={focusTextEditor}>
      <Controller name={id as FieldPath<TFieldValues>}
                  control={control}
                  defaultValue={valueDefault as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>}
                  rules={rules}
                  render={({ field: { onChange, value } }) =>
        <FabTextEditor onChange={onChange}
                       content={value}
                       limit={limit}
                       heading={heading}
                       bulletList={bulletList}
                       blockquote={blockquote}
                       video={video}
                       image={image}
                       link={link}
                       disabled={isDisabled}
                       ref={textEditorRef} />
      } />
    </AbstractFormItem>
  );
};
