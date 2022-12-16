import React from 'react';
import Select from 'react-select';
import { useTranslation } from 'react-i18next';
import { SelectOption } from '../../models/select';
import { MachineCategory } from '../../models/machine-category';

interface MachinesFiltersProps {
  onFilterChangedBy: (type: string, value: number | boolean | void) => void,
  machineCategories: Array<MachineCategory>,
}

/**
 * Allows filtering on machines list
 */
export const MachinesFilters: React.FC<MachinesFiltersProps> = ({ onFilterChangedBy, machineCategories }) => {
  const { t } = useTranslation('public');

  const defaultValue = { value: true, label: t('app.public.machines_filters.status_enabled') };
  const categoryDefaultValue = { value: null, label: t('app.public.machines_filters.all_machines') };

  /**
   * Provides boolean options in the react-select format (yes/no/all)
   */
  const buildBooleanOptions = (): Array<SelectOption<boolean>> => {
    return [
      defaultValue,
      { value: false, label: t('app.public.machines_filters.status_disabled') },
      { value: null, label: t('app.public.machines_filters.status_all') }
    ];
  };

  /**
   * Provides categories options in the react-select format
   */
  const buildCategoriesOptions = (): Array<SelectOption<number|void>> => {
    const options = machineCategories.map(c => {
      return { value: c.id, label: c.name };
    });
    return [categoryDefaultValue].concat(options);
  };

  /**
   * Callback triggered when the user selects a machine status in the dropdown list
   */
  const handleStatusSelected = (option: SelectOption<boolean>): void => {
    onFilterChangedBy('status', option.value);
  };

  /**
   * Callback triggered when the user selects a machine category in the dropdown list
   */
  const handleCategorySelected = (option: SelectOption<number>): void => {
    onFilterChangedBy('category', option.value);
  };

  return (
    <div className="machines-filters">
      <div className="filter-item">
        <label htmlFor="status">{t('app.public.machines_filters.show_machines')}</label>
        <Select defaultValue={defaultValue}
          id="status"
          className="status-select"
          onChange={handleStatusSelected}
          options={buildBooleanOptions()}/>
      </div>
      {machineCategories.length > 0 &&
        <div className="filter-item">
          <label htmlFor="category">{t('app.public.machines_filters.filter_by_machine_category')}</label>
          <Select defaultValue={categoryDefaultValue}
            id="machine_category"
            className="category-select"
            onChange={handleCategorySelected}
            options={buildCategoriesOptions()}/>
        </div>
      }
    </div>
  );
};
