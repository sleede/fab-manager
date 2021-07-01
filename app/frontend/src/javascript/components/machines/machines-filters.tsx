import React from 'react';
import Select from 'react-select';
import { useTranslation } from 'react-i18next';

interface MachinesFiltersProps {
  onStatusSelected: (enabled: boolean) => void,
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: boolean, label: string };

export const MachinesFilters: React.FC<MachinesFiltersProps> = ({ onStatusSelected }) => {
  const { t } = useTranslation('public');

  const defaultValue = { value: true, label: t('app.public.machines_filters.status_enabled') };

  /**
   * Provides boolean options in the react-select format (yes/no/all)
   */
  const buildBooleanOptions = (): Array<selectOption> => {
    return [
      defaultValue,
      { value: false, label: t('app.public.machines_filters.status_disabled') },
      { value: null, label: t('app.public.machines_filters.status_all') },
    ]
  }

  /**
   * Callback triggered when the user selects a machine status in the dropdown list
   */
  const handleStatusSelected = (option: selectOption): void => {
    onStatusSelected(option.value);
  }

  return (
    <div className="machines-filters">
      <div className="status-filter">
        <label htmlFor="status">{t('app.public.machines_filters.show_machines')}</label>
        <Select defaultValue={defaultValue}
                id="status"
                className="status-select"
                onChange={handleStatusSelected}
                options={buildBooleanOptions()}/>
      </div>
    </div>
  )
}
