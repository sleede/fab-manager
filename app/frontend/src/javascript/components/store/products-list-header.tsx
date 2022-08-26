import React from 'react';
import { useTranslation } from 'react-i18next';
import Select from 'react-select';
import Switch from 'react-switch';

interface ProductsListHeaderProps {
  productsCount: number,
  selectOptions: selectOption[],
  onSelectOptionsChange: (option: selectOption) => void,
  switchLabel?: string,
  switchChecked: boolean,
  onSwitch: (boolean) => void
}
/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
 type selectOption = { value: number, label: string };

/**
 * Renders an accordion item
 */
export const ProductsListHeader: React.FC<ProductsListHeaderProps> = ({ productsCount, selectOptions, onSelectOptionsChange, switchLabel, switchChecked, onSwitch }) => {
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
    <div className='products-list-header'>
      <div className='count'>
        <p>{t('app.admin.store.products_list_header.result_count')}<span>{productsCount}</span></p>
      </div>
      <div className="display">
        <div className='sort'>
          <p>{t('app.admin.store.products_list_header.display_options')}</p>
          <Select
            options={selectOptions}
            onChange={evt => onSelectOptionsChange(evt)}
            styles={customStyles}
          />
        </div>
        <div className='visibility'>
          <label>
            <span>{switchLabel || t('app.admin.store.products_list_header.visible_only')}</span>
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
      </div>
    </div>
  );
};
