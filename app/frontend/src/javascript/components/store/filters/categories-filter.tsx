import React, { useEffect, useState } from 'react';
import _ from 'lodash';
import ProductCategoryAPI from '../../../api/product-category';
import ProductLib from '../../../lib/product';
import { ProductCategory } from '../../../models/product-category';
import { FabButton } from '../../base/fab-button';
import { AccordionItem } from '../../base/accordion-item';
import { useTranslation } from 'react-i18next';

interface CategoriesFilterProps {
  onError: (message: string) => void,
  onApplyFilters: (categories: Array<ProductCategory>) => void,
  currentFilters: Array<ProductCategory>,
  openDefault?: boolean,
  instantUpdate?: boolean,
}

/**
 * Component to filter the products list by categories
 */
export const CategoriesFilter: React.FC<CategoriesFilterProps> = ({ onError, onApplyFilters, currentFilters, openDefault = false, instantUpdate = false }) => {
  const { t } = useTranslation('admin');

  const [productCategories, setProductCategories] = useState<ProductCategory[]>([]);
  const [openedAccordion, setOpenedAccordion] = useState<boolean>(openDefault);
  const [selectedCategories, setSelectedCategories] = useState<ProductCategory[]>(currentFilters || []);

  useEffect(() => {
    ProductCategoryAPI.index().then(data => {
      setProductCategories(ProductLib.sortCategories(data));
    }).catch(onError);
  }, []);

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
    let list = [...selectedCategories];
    const children = productCategories
      .filter(el => el.parent_id === currentCategory.id);
    const siblings = productCategories
      .filter(el => el.parent_id === currentCategory.parent_id && el.parent_id !== null);

    if (checked) {
      list.push(currentCategory);
      if (children.length) {
        // if a parent category is selected, we automatically select all its children
        list = [...Array.from(new Set([...list, ...children]))];
      }
      if (siblings.length && siblings.every(el => list.includes(el))) {
        // if a child category is selected, with every sibling of it, we automatically select its parent
        list.push(productCategories.find(p => p.id === siblings[0].parent_id));
      }
    } else {
      list.splice(list.indexOf(currentCategory), 1);
      const parent = productCategories.find(p => p.id === currentCategory.parent_id);
      if (currentCategory.parent_id && list.includes(parent)) {
        // if a child category is unselected, we unselect its parent
        list.splice(list.indexOf(parent), 1);
      }
      if (children.length) {
        // if a parent category is unselected, we unselect all its children
        children.forEach(child => {
          list.splice(list.indexOf(child), 1);
        });
      }
    }

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
          <FabButton onClick={() => onApplyFilters(selectedCategories)} className="is-info">{t('app.admin.store.categories_filter.filter_apply')}</FabButton>
        </div>
      </AccordionItem>
    </>
  );
};
