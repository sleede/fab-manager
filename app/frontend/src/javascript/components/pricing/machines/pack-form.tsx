import { useEffect, useState } from 'react';
import { Controller, SubmitHandler, useForm } from 'react-hook-form';
import { PrepaidPack } from '../../../models/prepaid-pack';
import { useTranslation } from 'react-i18next';
import { IFablab } from '../../../models/fablab';
import { SelectOption } from '../../../models/select';
import { FormInput } from '../../form/form-input';
import { FormSelect } from '../../form/form-select';
import { FormSwitch } from '../../form/form-switch';
import { FabInput } from '../../base/fab-input';

declare let Fablab: IFablab;

interface PackFormProps {
  formId: string,
  onSubmit: (pack: PrepaidPack) => void,
  pack?: PrepaidPack,
}

const ALL_INTERVALS = ['day', 'week', 'month', 'year'] as const;
type interval = typeof ALL_INTERVALS[number];

/**
 * A form component to create/edit a PrepaidPack.
 * The form validation must be created elsewhere, using the attribute form={formId}.
 */
export const PackForm: React.FC<PackFormProps> = ({ formId, onSubmit, pack }) => {
  const { t } = useTranslation('admin');

  const { handleSubmit, register, control, formState, setValue } = useForm<PrepaidPack>({ defaultValues: { ...pack } });

  const [formattedDuration, setFormattedDuration] = useState<number>(pack?.minutes || 60);
  /**
   * Callback triggered when the user validates the form
   */
  const submitForm: SubmitHandler<PrepaidPack> = (data:PrepaidPack) => {
    onSubmit(data);
  };

  /**
   * Convert all validity-intervals to the react-select format
   */
  const buildOptions = (): Array<SelectOption<interval>> => {
    return ALL_INTERVALS.map(i => intervalToOption(i));
  };

  /**
   * Convert the given validity-interval to the react-select format
   */
  const intervalToOption = (value: interval): SelectOption<interval> => {
    if (!value) return { value, label: '' };
    return { value, label: t(`app.admin.pack_form.intervals.${value}`, { COUNT: pack?.validity_count || 0 }) };
  };

  /**
   * Changes hours into minutes
   */
  const formatDuration = (value) => {
    setFormattedDuration(value * 60);
  };
  useEffect(() => {
    setValue('minutes', formattedDuration);
  }, [formattedDuration]);

  return (
    <form id={formId} onSubmit={handleSubmit(submitForm)} className="pack-form">
      <div className="duration">
        <label htmlFor="minutes">{t('app.admin.pack_form.hours')}</label>
        <Controller control={control}
                    name='minutes'
                    render={() => (
                      <FabInput id="minutes"
                            type='number'
                            min={1}
                            required
                            icon={<i className="fas fa-clock" />}
                            onChange={formatDuration}
                            defaultValue={formattedDuration / 60} />
                    )} />
      </div>

      <FormInput id="amount"
        register={register}
        formState={formState}
        type="number"
        step={0.01}
        icon={<i className="fas fa-money-bill" />}
        addOn={Fablab.intl_currency}
        rules={{ required: true, min: 0 }}
        label={t('app.admin.pack_form.amount')} />

      <label className='validity' htmlFor="validity_count">{t('app.admin.pack_form.validity_count')}</label>
      <div className="interval-inputs">
        <FormInput id="validity_count"
          register={register}
          formState={formState}
          type="number"
          icon={<i className="fas fa-calendar-week" />}
          rules={{ min: 0 }}/>
        <FormSelect id="validity_interval"
                    control={control}
                    options={buildOptions()}
                    className="select-interval"
                    placeholder={t('app.admin.pack_form.select_interval')}/>
      </div>

      <FormSwitch id="disabled"
                  control={control}
                  formState={formState}
                  label={t('app.admin.pack_form.disabled')} />
    </form>
  );
};
