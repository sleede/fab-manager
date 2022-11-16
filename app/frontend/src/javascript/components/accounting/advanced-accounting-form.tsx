import { useEffect, useState } from 'react';
import SettingAPI from '../../api/setting';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { FormInput } from '../form/form-input';
import { useTranslation } from 'react-i18next';

interface AdvancedAccountingFormProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  onError: (message: string) => void
}

/**
 * This component is a partial form, to be included in a resource form managed by react-hook-form.
 * It will add advanced accounting attributes to the parent form, if they are enabled
 */
export const AdvancedAccountingForm = <TFieldValues extends FieldValues>({ register, onError }: AdvancedAccountingFormProps<TFieldValues>) => {
  const [isEnabled, setIsEnabled] = useState<boolean>(false);

  const { t } = useTranslation('admin');

  useEffect(() => {
    SettingAPI.get('advanced_accounting').then(res => setIsEnabled(res.value === 'true')).catch(onError);
  }, []);

  return (
    <div className="advanced-accounting-form">
      {isEnabled && <div>
        <h4>{t('app.admin.advanced_accounting_form.title')}</h4>
        <FormInput register={register}
                   id="advanced_accounting_attributes.code"
                   label={t('app.admin.advanced_accounting_form.code')} />
        <FormInput register={register}
                   id="advanced_accounting_attributes.analytical_section"
                   label={t('app.admin.advanced_accounting_form.analytical_section')} />
      </div>}
    </div>
  );
};
