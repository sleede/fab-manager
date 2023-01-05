import { UseFormRegister, Validate } from 'react-hook-form';
import { Control, FormState } from 'react-hook-form/dist/types/form';

export type ruleTypes = {
  required?: boolean | string,
  pattern?: RegExp | { value: RegExp, message: string },
  minLength?: number | { value: number, message: string },
  maxLength?: number | { value: number, message: string },
  min?: number,
  max?: number,
  validate?: Validate<unknown>;
};

/**
 * `error` and `warning` props can be manually set.
 * Automatic error handling is done through the `formState` prop.
 * Even for manual error/warning, the `formState` prop is required, because it is used to determine if the field is dirty.
 */
export interface AbstractFormComponent<TFieldValues> {
  error?: { message: string },
  warning?: { message: string },
  rules?: ruleTypes,
  formState?: FormState<TFieldValues>;
}

export interface FormComponent<TFieldValues> extends AbstractFormComponent<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
}

export interface FormControlledComponent<TFieldValues, TContext extends object> extends AbstractFormComponent<TFieldValues> {
  control: Control<TFieldValues, TContext>
}
