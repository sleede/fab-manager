import React, { useEffect, useState } from 'react';
import _ from 'lodash';
import ProductLib from '../../../lib/product';
import { ProductCategory } from '../../../models/product-category';
import { FabButton } from '../../base/fab-button';
import { AccordionItem } from '../../base/accordion-item';
import { useTranslation } from 'react-i18next';

interface CategoriesFilterProps {
  productCategories: Array<ProductCategory>,
  onApplyFilters: (categories: Array<ProductCategory>) => void,
  currentFilters: Array<ProductCategory>,
  openDefault?: boolean,
  instantUpdate?: boolean,
}

/**
 * Component to filter the products list by categories
 */
export const CategoriesFilter: React.FC<CategoriesFilterProps> = ({ productCategories, onApplyFilters, currentFilters, openDefault = false, instantUpdate = false }) => {
  const { t } = useTranslation('admin');

  const [openedAccordion, setOpenedAccordion] = useState<boolean>(openDefault);
  const [selectedCategories, setSelectedCategories] = useState<ProductCategory[]>(currentFilters || []);

  useEffect(() => {
    if (currentFilters && !_.isEqual(currentFilters, selectedCategories)) {
      setSelectedCategories(currentFilters);
    }
  }, [currentFilters]);

  /**
   * Open/close the accordion item
   */
  const handleAccordion = (id, state: boolean) => {
    setOpenedAccordion(state);
  };

  /**
   * Callback triggered when a category filter is selected or unselected.
   * This may cause other categories to be selected or unselected accordingly.
   */
  const handleSelectCategory = (currentCategory: ProductCategory, checked: boolean) => {
    const list = ProductLib.categoriesSelectionTree(productCategories, selectedCategories, currentCategory, checked ? 'add' : 'remove');

    setSelectedCategories(list);
    if (instantUpdate) {
      onApplyFilters(list);
    }
  };

  return (
    <>
      <AccordionItem id={0}
                     isOpen={openedAccordion}
                     onChange={handleAccordion}
                     label={t('app.admin.store.categories_filter.filter_categories')}>
        <div className='content'>
          <div className="group u-scrollbar">
            {productCategories.map(pc => (
              <label key={pc.id} className={pc.parent_id ? 'offset' : ''}>
                <input type="checkbox" checked={selectedCategories.includes(pc)} onChange={(event) => handleSelectCategory(pc, event.target.checked)} />
                <p>{pc.name}</p>
              </label>
            ))}
          </div>
          <FabButton onClick={() => onApplyFilters(selectedCategories)} className="is-secondary">{t('app.admin.store.categories_filter.filter_apply')}</FabButton>
        </div>
      </AccordionItem>
    </>
  );
};
