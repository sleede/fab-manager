import React, { BaseSyntheticEvent } from 'react';
import Select from 'react-select';
import { PrepaidPack } from '../../models/prepaid-pack';
import { useTranslation } from 'react-i18next';
import { useImmer } from 'use-immer';
import { FabInput } from '../base/fab-input';
import { IFablab } from '../../models/fablab';

declare var Fablab: IFablab;

interface PackFormProps {
  formId: string,
  onSubmit: (pack: PrepaidPack) => void,
  packData?: PrepaidPack,
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
export const PackForm: React.FC<PackFormProps> = ({ formId, onSubmit, packData }) => {
  const [pack, updatePack] = useImmer<PrepaidPack>(packData || {} as PrepaidPack);

  const { t } = useTranslation('admin');

  /**
   * Convert all validity intervals to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return ALL_INTERVALS.map(i => {
      return { value: i, label: t(`app.admin.pack_form.intervals.${i}`, { COUNT: pack.validity_count || 0 }) };
    });
  }

  /**
   * Callback triggered when the user sends the form.
   */
  const handleSubmit = (event: BaseSyntheticEvent): void => {
    event.preventDefault();
    onSubmit(pack);
  }

  /**
   * Callback triggered when the user inputs an amount for the current pack.
   */
  const handleUpdateAmount = (amount: string) => {
    updatePack(draft => {
      draft.amount = parseFloat(amount);
    });
  }

  /**
   * Callback triggered when the user inputs a number of hours for the current pack.
   */
  const handleUpdateHours = (hours: string) => {
    updatePack(draft => {
      draft.minutes = parseInt(hours, 10) * 60;
    });
  }

  /**
   * Callback triggered when the user inputs a number of periods for the current pack.
   */
  const handleUpdateValidityCount = (count: string) => {
    updatePack(draft => {
      draft.validity_count = parseInt(count, 10);
    });
  }

  /**
   * Callback triggered when the user selects a type of interval for the current pack.
   */
  const handleUpdateValidityInterval = (option: selectOption) => {
    updatePack(draft => {
      draft.validity_interval = option.value as interval;
    });
  }

  return (
    <form id={formId} onSubmit={handleSubmit} className="pack-form">
      <label htmlFor="hours">{t('app.admin.pack_form.hours')} *</label>
      <FabInput id="hours"
                type="number"
                defaultValue={pack?.minutes / 60 || ''}
                onChange={handleUpdateHours}
                min={1}
                icon={<i className="fas fa-clock" />}
                required />
      <label htmlFor="amount">{t('app.admin.pack_form.amount')} *</label>
      <FabInput id="amount"
                type="number"
                step={0.01}
                min={0}
                defaultValue={pack?.amount || ''}
                onChange={handleUpdateAmount}
                icon={<i className="fas fa-money-bill" />}
                addOn={Fablab.intl_currency}
                required />
      <label htmlFor="validity_count">{t('app.admin.pack_form.validity_count')}</label>
      <div className="interval-inputs">
        <FabInput id="validity_count"
                  type="number"
                  min={0}
                  defaultValue={pack?.validity_count || ''}
                  onChange={handleUpdateValidityCount}
                  icon={<i className="fas fa-calendar-week" />} />
        <Select placeholder={t('app.admin.pack_form.select_interval')}
                className="select-interval"
                defaultValue={pack?.validity_interval}
                onChange={handleUpdateValidityInterval}
                options={buildOptions()} />
      </div>
    </form>
  );
}
