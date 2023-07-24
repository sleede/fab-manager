import { useState, useEffect } from 'react';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FieldPath } from 'react-hook-form/dist/types/path';
import { useTranslation } from 'react-i18next';

interface GenderInputProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  disabled?: boolean|((id: string) => boolean),
  required?: boolean,
  tooltip?: string
}

/**
 * Input component to set the gender for the user
 */
export const GenderInput = <TFieldValues extends FieldValues>({ register, disabled = false, required, tooltip }: GenderInputProps<TFieldValues>) => {
  const { t } = useTranslation('shared');

  const [isDisabled, setIsDisabled] = useState<boolean>(false);

  useEffect(() => {
    if (typeof disabled === 'function') {
      setIsDisabled(disabled('statistic_profile_attributes.gender'));
    } else {
      setIsDisabled(disabled);
    }
  }, [disabled]);

  return (
    <fieldset className="gender-input">
      <legend className={required ? 'is-required' : ''}>{t('app.shared.gender_input.label')}</legend>
      <label>
        <p>{t('app.shared.gender_input.man')}</p>
        <input type="radio"
               name='gender'
               value="true"
               required={required}
               disabled={isDisabled}
               {...register('statistic_profile_attributes.gender' as FieldPath<TFieldValues>)} />
      </label>
      <label>
        <p>{t('app.shared.gender_input.woman')}</p>
        <input type="radio"
               name='gender'
               value="false"
               disabled={isDisabled}
               {...register('statistic_profile_attributes.gender' as FieldPath<TFieldValues>)} />
      </label>
      {tooltip && <div className="fab-tooltip">
        <span className="trigger"><i className="fa fa-question-circle" /></span>
        <div className="content">{tooltip}</div>
      </div>}
    </fieldset>
  );
};
