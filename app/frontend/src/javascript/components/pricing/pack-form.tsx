import React, { BaseSyntheticEvent } from 'react';
import Select from 'react-select';
import Switch from 'react-switch';
import { PrepaidPack } from '../../models/prepaid-pack';
import { useTranslation } from 'react-i18next';
import { useImmer } from 'use-immer';
import { FabInput } from '../base/fab-input';
import { IFablab } from '../../models/fablab';

declare let Fablab: IFablab;

interface PackFormProps {
  formId: string,
  onSubmit: (pack: PrepaidPack) => void,
  pack?: PrepaidPack,
}

const ALL_INTERVALS = ['day', 'week', 'month', 'year'] as const;
type interval = typeof ALL_INTERVALS[number];

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: interval, label: string };

/**
 * A form component to create/edit a PrepaidPack.
 * The form validation must be created elsewhere, using the attribute form={formId}.
 */
export const PackForm: React.FC<PackFormProps> = ({ formId, onSubmit, pack }) => {
  const [packData, updatePackData] = useImmer<PrepaidPack>(pack || {} as PrepaidPack);

  const { t } = useTranslation('admin');

  /**
   * Convert all validity-intervals to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return ALL_INTERVALS.map(i => intervalToOption(i));
  };

  /**
   * Convert the given validity-interval to the react-select format
   */
  const intervalToOption = (value: interval): selectOption => {
    if (!value) return { value, label: '' };

    return { value, label: t(`app.admin.pack_form.intervals.${value}`, { COUNT: packData.validity_count || 0 }) };
  };

  /**
   * Callback triggered when the user sends the form.
   */
  const handleSubmit = (event: BaseSyntheticEvent): void => {
    event.preventDefault();
    onSubmit(packData);
  };

  /**
   * Callback triggered when the user inputs an amount for the current pack.
   */
  const handleUpdateAmount = (amount: string) => {
    updatePackData(draft => {
      draft.amount = parseFloat(amount);
    });
  };

  /**
   * Callback triggered when the user inputs a number of hours for the current pack.
   */
  const handleUpdateHours = (hours: string) => {
    updatePackData(draft => {
      draft.minutes = parseInt(hours, 10) * 60;
    });
  };

  /**
   * Callback triggered when the user inputs a number of periods for the current pack.
   */
  const handleUpdateValidityCount = (count: string) => {
    updatePackData(draft => {
      draft.validity_count = parseInt(count, 10);
    });
  };

  /**
   * Callback triggered when the user selects a type of interval for the current pack.
   */
  const handleUpdateValidityInterval = (option: selectOption) => {
    updatePackData(draft => {
      draft.validity_interval = option.value as interval;
    });
  };

  /**
   * Callback triggered when the user disables the pack.
   */
  const handleUpdateDisabled = (checked: boolean) => {
    updatePackData(draft => {
      draft.disabled = checked;
    });
  };

  return (
    <form id={formId} onSubmit={handleSubmit} className="pack-form">
      <label htmlFor="hours">{t('app.admin.pack_form.hours')} *</label>
      <FabInput id="hours"
        type="number"
        defaultValue={packData?.minutes / 60 || ''}
        onChange={handleUpdateHours}
        min={1}
        icon={<i className="fas fa-clock" />}
        required />
      <label htmlFor="amount">{t('app.admin.pack_form.amount')} *</label>
      <FabInput id="amount"
        type="number"
        step={0.01}
        min={0}
        defaultValue={packData?.amount || ''}
        onChange={handleUpdateAmount}
        icon={<i className="fas fa-money-bill" />}
        addOn={Fablab.intl_currency}
        required />
      <label htmlFor="validity_count">{t('app.admin.pack_form.validity_count')}</label>
      <div className="interval-inputs">
        <FabInput id="validity_count"
          type="number"
          min={0}
          defaultValue={packData?.validity_count || ''}
          onChange={handleUpdateValidityCount}
          icon={<i className="fas fa-calendar-week" />} />
        <Select placeholder={t('app.admin.pack_form.select_interval')}
          className="select-interval"
          defaultValue={intervalToOption(packData?.validity_interval)}
          onChange={handleUpdateValidityInterval}
          options={buildOptions()} />
      </div>
      <label htmlFor="disabled">{t('app.admin.pack_form.disabled')}</label>
      <div>
        <Switch checked={packData?.disabled || false} onChange={handleUpdateDisabled} id="disabled" />
      </div>
    </form>
  );
};
