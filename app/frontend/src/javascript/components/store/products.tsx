// TODO: Remove next eslint-disable
/* eslint-disable @typescript-eslint/no-unused-vars */
import React, { useState, useEffect } from 'react';
import { useImmer } from 'use-immer';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { Product } from '../../models/product';
import { ProductCategory } from '../../models/product-category';
import { FabButton } from '../base/fab-button';
import { ProductsList } from './products-list';
import ProductAPI from '../../api/product';
import ProductCategoryAPI from '../../api/product-category';
import MachineAPI from '../../api/machine';
import { CaretDown, X } from 'phosphor-react';
import Switch from 'react-switch';
import { Machine } from '../../models/machine';

declare const Application: IApplication;

interface ProductsProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows all Products and filter
 */
const Products: React.FC<ProductsProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [products, setProducts] = useState<Array<Product>>([]);
  const [filteredProductsList, setFilteredProductList] = useImmer<Array<Product>>([]);
  const [filterVisible, setFilterVisible] = useState<boolean>(false);
  const [clearFilters, setClearFilters] = useState<boolean>(false);
  const [filters, setFilters] = useImmer<Filters>(initFilters);
  const [productCategories, setProductCategories] = useState<ProductCategory[]>([]);
  const [machines, setMachines] = useState<checklistOption[]>([]);

  useEffect(() => {
    ProductAPI.index().then(data => {
      setProducts(data);
      setFilteredProductList(data);
    });
  }, []);

  useEffect(() => {
    ProductCategoryAPI.index().then(data => {
      // Map product categories by position
      const sortedCategories = data
        .filter(c => !c.parent_id)
        .sort((a, b) => a.position - b.position);
      const childrenCategories = data
        .filter(c => typeof c.parent_id === 'number')
        .sort((a, b) => b.position - a.position);
      childrenCategories.forEach(c => {
        const parentIndex = sortedCategories.findIndex(i => i.id === c.parent_id);
        sortedCategories.splice(parentIndex + 1, 0, c);
      });
      setProductCategories(sortedCategories);
    }).catch(onError);
    MachineAPI.index({ disabled: false }).then(data => {
      setMachines(buildChecklistOptions(data));
    }).catch(onError);
  }, []);

  useEffect(() => {
    applyFilters();
    setClearFilters(false);
  }, [filterVisible, clearFilters]);

  /**
   * Goto edit product page
   */
  const editProduct = (product: Product) => {
    window.location.href = `/#!/admin/store/products/${product.id}/edit`;
  };

  /**
   * Delete a product
   */
  const deleteProduct = async (productId: number): Promise<void> => {
    try {
      await ProductAPI.destroy(productId);
      const data = await ProductAPI.index();
      setProducts(data);
      onSuccess(t('app.admin.store.products.successfully_deleted'));
    } catch (e) {
      onError(t('app.admin.store.products.unable_to_delete') + e);
    }
  };

  /**
   * Goto new product page
   */
  const newProduct = (): void => {
    window.location.href = '/#!/admin/store/products/new';
  };

  /**
   * Filter: toggle hidden products visibility
   */
  const toggleVisible = (checked: boolean) => {
    setFilterVisible(checked);
  };

  /**
   * Filter: by categories
   */
  const handleSelectCategory = (c: ProductCategory, checked) => {
    let list = [...filters.categories];
    const children = productCategories
      .filter(el => el.parent_id === c.id)
      .map(el => el.id);
    const siblings = productCategories
      .filter(el => el.parent_id === c.parent_id && el.parent_id !== null);

    if (checked) {
      list.push(c.id);
      if (children.length) {
        const unic = Array.from(new Set([...list, ...children]));
        list = [...unic];
      }
      if (siblings.length && siblings.every(el => list.includes(el.id))) {
        list.push(siblings[0].parent_id);
      }
    } else {
      list.splice(list.indexOf(c.id), 1);
      if (c.parent_id && list.includes(c.parent_id)) {
        list.splice(list.indexOf(c.parent_id), 1);
      }
      if (children.length) {
        children.forEach(child => {
          list.splice(list.indexOf(child), 1);
        });
      }
    }
    setFilters(draft => {
      return { ...draft, categories: list };
    });
  };

  /**
   * Filter: by machines
   */
  const handleSelectMachine = (m: checklistOption, checked) => {
    const list = [...filters.machines];
    checked
      ? list.push(m.value)
      : list.splice(list.indexOf(m.value), 1);
    setFilters(draft => {
      return { ...draft, machines: list };
    });
  };

  /**
   * Apply filters
   */
  const applyFilters = () => {
    let updatedList = [...products];
    if (filterVisible) {
      updatedList = updatedList.filter(p => p.is_active);
    }
    if (filters.categories.length) {
      updatedList = updatedList.filter(p => filters.categories.includes(p.product_category_id));
    }
    if (filters.machines.length) {
      updatedList = updatedList.filter(p => {
        return p.machine_ids.find(m => filters.machines.includes(m));
      });
    }
    setFilteredProductList(updatedList);
  };

  /**
   * Clear filters
   */
  const clearAllFilters = () => {
    setFilters(initFilters);
    setClearFilters(true);
  };

  return (
    <div className='products'>
      <header>
        <h2>{t('app.admin.store.products.all_products')}</h2>
        <div className='grpBtn'>
          <FabButton className="main-action-btn" onClick={newProduct}>{t('app.admin.store.products.create_a_product')}</FabButton>
        </div>
      </header>
      <div className='layout'>
        <div className='products-filters span-3'>
          <header>
            <h3>{t('app.admin.store.products.filter')}</h3>
            <div className='grpBtn'>
              <FabButton onClick={clearAllFilters} className="is-black">{t('app.admin.store.products.filter_clear')}</FabButton>
            </div>
          </header>
          <div className='accordion'>
            <div className='accordion-item'>
              <input type="checkbox" defaultChecked />
              <header>{t('app.admin.store.products.filter_categories')}
                <CaretDown size={16} weight="bold" /></header>
              <div className='content'>
                <div className="list scrollbar">
                  {productCategories.map(pc => (
                    <label key={pc.id} className={pc.parent_id ? 'offset' : ''}>
                      <input type="checkbox" checked={filters.categories.includes(pc.id)} onChange={(event) => handleSelectCategory(pc, event.target.checked)} />
                      <p>{pc.name}</p>
                    </label>
                  ))}
                </div>
                <FabButton onClick={applyFilters} className="is-info">{t('app.admin.store.products.filter_apply')}</FabButton>
              </div>
            </div>

            <div className='accordion-item'>
              <input type="checkbox" defaultChecked />
              <header>{t('app.admin.store.products.filter_machines')}
                <CaretDown size={16} weight="bold" /></header>
              <div className='content'>
                <div className="list scrollbar">
                  {machines.map(m => (
                    <label key={m.value}>
                      <input type="checkbox" checked={filters.machines.includes(m.value)} onChange={(event) => handleSelectMachine(m, event.target.checked)} />
                      <p>{m.label}</p>
                    </label>
                  ))}
                </div>
                <FabButton onClick={applyFilters} className="is-info">{t('app.admin.store.products.filter_apply')}</FabButton>
              </div>
            </div>
          </div>
        </div>
        <div className='products-list span-7'>
          <div className='status'>
            <div className='count'>
              <p>{t('app.admin.store.products.result_count')}<span>{filteredProductsList.length}</span></p>
            </div>
            <div className="display">
              <div className='sort'>
                <p>{t('app.admin.store.products.display_options')}</p>
                <select>
                  <option value="A">A</option>
                  <option value="B">B</option>
                </select>
              </div>
              <div className='visibility'>
                <label>
                  <span>{t('app.admin.store.products.visible_only')}</span>
                  <Switch
                    checked={filterVisible}
                    onChange={(checked) => toggleVisible(checked)}
                    width={40}
                    height={19}
                    uncheckedIcon={false}
                    checkedIcon={false}
                    handleDiameter={15} />
                </label>
              </div>
            </div>
          </div>
          <div className='features'>
            <div className='features-item'>
              <p>feature name</p>
              <button><X size={16} weight="light" /></button>
            </div>
            <div className='features-item'>
              <p>long feature name</p>
              <button><X size={16} weight="light" /></button>
            </div>
          </div>
          <ProductsList
            products={filteredProductsList}
            onEdit={editProduct}
            onDelete={deleteProduct}
          />
        </div>
      </div>
    </div>
  );
};

const ProductsWrapper: React.FC<ProductsProps> = ({ onSuccess, onError }) => {
  return (
    <Loader>
      <Products onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};

Application.Components.component('products', react2angular(ProductsWrapper, ['onSuccess', 'onError']));

/**
 * Option format, expected by checklist
 */
type checklistOption = { value: number, label: string };

/**
 * Convert the provided array of items to the checklist format
 */
const buildChecklistOptions = (items: Array<{ id?: number, name: string }>): Array<checklistOption> => {
  return items.map(t => {
    return { value: t.id, label: t.name };
  });
};

const initFilters: Filters = {
  categories: [],
  machines: [],
  keywords: [],
  internalStock: {
    from: 0,
    to: null
  },
  externalStock: {
    from: 0,
    to: null
  }
};

interface Stock {
  from: number,
  to: number
}

interface Filters {
  categories: number[],
  machines: number[],
  keywords: string[],
  internalStock: Stock,
  externalStock: Stock
}
