import React from 'react';
import { useTranslation } from 'react-i18next';
import Select from 'react-select';
import Switch from 'react-switch';
import { SortOption } from '../../models/api';

interface StoreListHeaderProps {
  productsCount: number,
  selectOptions: selectOption[],
  onSelectOptionsChange: (option: selectOption) => void,
  selectValue?: SortOption,
  switchLabel?: string,
  switchChecked?: boolean,
  onSwitch?: (boolean) => void
}
/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
 type selectOption = { value: SortOption, label: string };

/**
 * Renders an accordion item
 */
export const StoreListHeader: React.FC<StoreListHeaderProps> = ({ productsCount, selectOptions, onSelectOptionsChange, switchLabel, switchChecked, onSwitch, selectValue }) => {
  const { t } = useTranslation('admin');

  // Styles the React-select component
  const customStyles = {
    control: base => ({
      ...base,
      width: '20ch',
      border: 'none',
      backgroundColor: 'transparent'
    }),
    indicatorSeparator: () => ({
      display: 'none'
    })
  };

  return (
    <div className='store-list-header'>
      <div className='count'>
        <p>{t('app.admin.store.store_list_header.result_count')}<span>{productsCount}</span></p>
      </div>
      <div className="display">
        <div className='sort'>
          <p>{t('app.admin.store.store_list_header.sort')}</p>
          <Select
            options={selectOptions}
            onChange={evt => onSelectOptionsChange(evt)}
            value={selectOptions.find(option => option.value === selectValue)}
            styles={customStyles}
          />
        </div>
        {onSwitch &&
          <div className='visibility'>
            <label>
              <span>{switchLabel || t('app.admin.store.store_list_header.visible_only')}</span>
              <Switch
                checked={switchChecked}
                onChange={(checked) => onSwitch(checked)}
                width={40}
                height={19}
                uncheckedIcon={false}
                checkedIcon={false}
                handleDiameter={15} />
            </label>
          </div>
        }
      </div>
    </div>
  );
};
