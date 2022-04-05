import { FieldErrors, UseFormRegister, Validate } from 'react-hook-form';
import { Control } from 'react-hook-form/dist/types/form';

export type ruleTypes<TFieldValues> = {
  required?: boolean | string,
  pattern?: RegExp | {value: RegExp, message: string},
  minLength?: number,
  maxLength?: number,
  min?: number,
  max?: number,
  validate?: Validate<TFieldValues>;
};

export interface FormComponent<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  error?: FieldErrors,
  rules?: ruleTypes<TFieldValues>,
}

export interface FormControlledComponent<TFieldValues, TContext extends object> {
  control: Control<TFieldValues, TContext>,
  error?: FieldErrors,
  rules?: ruleTypes<TFieldValues>,
}
