/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
export type SelectOption<TOptionValue, TOptionLabel = string> = { value: TOptionValue, label: TOptionLabel }

/**
 * Checklist Option format
 */
export type ChecklistOption<TOptionValue> = { value: TOptionValue, label: string };
