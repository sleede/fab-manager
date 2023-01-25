import { UseFormRegister, Validate } from 'react-hook-form';
import { Control, FormState } from 'react-hook-form/dist/types/form';

export type ruleTypes = {
  required?: boolean | string | { value: boolean, message: string },
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
interface AbstractFormComponentCommon {
  error?: { message: string },
  warning?: { message: string }
}

type AbstractFormComponentRules<TFieldValues> =
  { rules: ruleTypes, formState: FormState<TFieldValues> } |
  { rules?: never, formState?: FormState<TFieldValues> };

export type AbstractFormComponent<TFieldValues> = AbstractFormComponentCommon & AbstractFormComponentRules<TFieldValues>;

export type FormComponent<TFieldValues> = AbstractFormComponent<TFieldValues> & {
  register: UseFormRegister<TFieldValues>,
}

export type FormControlledComponent<TFieldValues, TContext extends object> = AbstractFormComponent<TFieldValues> & {
  control: Control<TFieldValues, TContext>
}
