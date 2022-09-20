import React, { useState, useEffect } from 'react';
import { useImmer } from 'use-immer';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { Product } from '../../models/product';
import { ProductCategory } from '../../models/product-category';
import { useForm } from 'react-hook-form';
import { FabButton } from '../base/fab-button';
import { ProductItem } from './product-item';
import ProductAPI from '../../api/product';
import ProductCategoryAPI from '../../api/product-category';
import MachineAPI from '../../api/machine';
import { AccordionItem } from './accordion-item';
import { CaretDoubleUp, X } from 'phosphor-react';
import { StoreListHeader } from './store-list-header';
import { FabPagination } from '../base/fab-pagination';
import ProductLib from '../../lib/product';
import { FormInput } from '../form/form-input';
import { FormSelect } from '../form/form-select';

declare const Application: IApplication;

interface ProductsProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}
/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
 type selectOption = { value: number, label: string };

/** This component shows the admin view of the store */
const Products: React.FC<ProductsProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const { register, control, getValues } = useForm();

  const [filteredProductsList, setFilteredProductList] = useImmer<Array<Product>>([]);
  const [features, setFeatures] = useImmer<Filters>(initFilters);
  const [filterVisible, setFilterVisible] = useState<boolean>(false);
  const [filters, setFilters] = useImmer<Filters>(initFilters);
  const [clearFilters, setClearFilters] = useState<boolean>(false);
  const [productCategories, setProductCategories] = useState<ProductCategory[]>([]);
  const [machines, setMachines] = useState<checklistOption[]>([]);
  const [update, setUpdate] = useState(false);
  const [accordion, setAccordion] = useState({});
  const [filtersPanel, setFiltersPanel] = useState<boolean>(true);
  const [pageCount, setPageCount] = useState<number>(0);
  const [currentPage, setCurrentPage] = useState<number>(1);

  useEffect(() => {
    ProductAPI.index({ page: 1, is_active: filterVisible }).then(data => {
      setPageCount(data.total_pages);
      setFilteredProductList(data.products);
    });

    ProductCategoryAPI.index().then(data => {
      setProductCategories(ProductLib.sortCategories(data));
    }).catch(onError);

    MachineAPI.index({ disabled: false }).then(data => {
      setMachines(buildChecklistOptions(data));
    }).catch(onError);
  }, []);

  useEffect(() => {
    applyFilters();
    setClearFilters(false);
    setUpdate(false);
  }, [filterVisible, clearFilters, update === true]);

  /** Handle products pagination */
  const handlePagination = (page: number) => {
    if (page !== currentPage) {
      ProductAPI.index({ page, is_active: filterVisible }).then(data => {
        setCurrentPage(page);
        setFilteredProductList(data.products);
        setPageCount(data.total_pages);
        window.document.getElementById('content-main').scrollTo({ top: 100, behavior: 'smooth' });
      }).catch(() => {
        onError(t('app.admin.store.products.unexpected_error_occurred'));
      });
    }
  };

  /** Goto edit product page */
  const editProduct = (product: Product) => {
    window.location.href = `/#!/admin/store/products/${product.id}/edit`;
  };

  /** Delete a product */
  const deleteProduct = async (productId: number): Promise<void> => {
    try {
      await ProductAPI.destroy(productId);
      const data = await ProductAPI.index();
      setFilteredProductList(data.products);
      onSuccess(t('app.admin.store.products.successfully_deleted'));
    } catch (e) {
      onError(t('app.admin.store.products.unable_to_delete') + e);
    }
  };

  /** Goto new product page */
  const newProduct = (): void => {
    window.location.href = '/#!/admin/store/products/new';
  };

  /** Filter: toggle non-available products visibility */
  const toggleVisible = (checked: boolean) => {
    setFilterVisible(!filterVisible);
    console.log('Display on the shelf product only:', checked);
  };

  /** Filter: by categories */
  const handleSelectCategory = (c: ProductCategory, checked: boolean, instantUpdate?: boolean) => {
    let list = [...filters.categories];
    const children = productCategories
      .filter(el => el.parent_id === c.id);
    const siblings = productCategories
      .filter(el => el.parent_id === c.parent_id && el.parent_id !== null);

    if (checked) {
      list.push(c);
      if (children.length) {
        const unique = Array.from(new Set([...list, ...children]));
        list = [...unique];
      }
      if (siblings.length && siblings.every(el => list.includes(el))) {
        list.push(productCategories.find(p => p.id === siblings[0].parent_id));
      }
    } else {
      list.splice(list.indexOf(c), 1);
      const parent = productCategories.find(p => p.id === c.parent_id);
      if (c.parent_id && list.includes(parent)) {
        list.splice(list.indexOf(parent), 1);
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
    if (instantUpdate) {
      setUpdate(true);
    }
  };

  /** Filter: by machines */
  const handleSelectMachine = (m: checklistOption, checked, instantUpdate?) => {
    const list = [...filters.machines];
    checked
      ? list.push(m)
      : list.splice(list.indexOf(m), 1);
    setFilters(draft => {
      return { ...draft, machines: list };
    });
    if (instantUpdate) {
      setUpdate(true);
    }
  };

  /** Filter: by keyword or ref */
  const handleKeyword = (evt: React.ChangeEvent<HTMLInputElement>) => {
    setFilters(draft => {
      return { ...draft, keywords: evt.target.value };
    });
  };

  /** Filter: by stock range */
  const handleStockRange = () => {
    setFilters(draft => {
      return {
        ...draft,
        stock_type: buildStockOptions()[getValues('stock_type')].label,
        stock_from: getValues('stock_from'),
        stock_to: getValues('stock_to')
      };
    });
  };

  /** Creates sorting options to the react-select format */
  const buildStockOptions = (): Array<selectOption> => {
    return [
      { value: 0, label: t('app.admin.store.products.stock_internal') },
      { value: 1, label: t('app.admin.store.products.stock_external') }
    ];
  };

  /** Display option: sorting */
  const handleSorting = (option: selectOption) => {
    console.log('Sort option:', option);
  };

  /** Apply filters */
  const applyFilters = () => {
    let tags = initFilters;

    if (filters.categories.length) {
      tags = { ...tags, categories: [...filters.categories] };
    }

    if (filters.machines.length) {
      tags = { ...tags, machines: [...filters.machines] };
    }

    setFeatures(tags);
    console.log('Apply filters:', filters);
  };

  /** Clear filters */
  const clearAllFilters = () => {
    setFilters(initFilters);
    setClearFilters(true);
    console.log('Clear all filters');
  };

  /** Creates sorting options to the react-select format */
  const buildSortOptions = (): Array<selectOption> => {
    return [
      { value: 0, label: t('app.admin.store.products.sort.name_az') },
      { value: 1, label: t('app.admin.store.products.sort.name_za') },
      { value: 2, label: t('app.admin.store.products.sort.price_low') },
      { value: 3, label: t('app.admin.store.products.sort.price_high') }
    ];
  };

  /** Open/close accordion items */
  const handleAccordion = (id, state) => {
    setAccordion({ ...accordion, [id]: state });
  };

  return (
    <div className='products'>
      <header>
        <h2>{t('app.admin.store.products.all_products')}</h2>
        <div className='grpBtn'>
          <FabButton className="main-action-btn" onClick={newProduct}>{t('app.admin.store.products.create_a_product')}</FabButton>
        </div>
      </header>
      <aside className={`store-filters ${filtersPanel ? '' : 'collapsed'}`}>
        <header>
          <h3>{t('app.admin.store.products.filter')}</h3>
          <div className='grpBtn'>
            <FabButton onClick={clearAllFilters} className="is-black">{t('app.admin.store.products.filter_clear')}</FabButton>
            <CaretDoubleUp className='filters-toggle' size={16} weight="bold" onClick={() => setFiltersPanel(!filtersPanel)} />
          </div>
        </header>
        <div className='grp accordion'>
          <AccordionItem id={0}
            isOpen={accordion[0]}
            onChange={handleAccordion}
            label={t('app.admin.store.products.filter_categories')}
          >
            <div className='content'>
              <div className="group u-scrollbar">
                {productCategories.map(pc => (
                  <label key={pc.id} className={pc.parent_id ? 'offset' : ''}>
                    <input type="checkbox" checked={filters.categories.includes(pc)} onChange={(event) => handleSelectCategory(pc, event.target.checked)} />
                    <p>{pc.name}</p>
                  </label>
                ))}
              </div>
              <FabButton onClick={() => setUpdate(true)} className="is-info">{t('app.admin.store.products.filter_apply')}</FabButton>
            </div>
          </AccordionItem>

          <AccordionItem id={1}
            isOpen={accordion[1]}
            onChange={handleAccordion}
            label={t('app.admin.store.products.filter_machines')}
          >
            <div className='content'>
              <div className="group u-scrollbar">
                {machines.map(m => (
                  <label key={m.value}>
                    <input type="checkbox" checked={filters.machines.includes(m)} onChange={(event) => handleSelectMachine(m, event.target.checked)} />
                    <p>{m.label}</p>
                  </label>
                ))}
              </div>
              <FabButton onClick={() => setUpdate(true)} className="is-info">{t('app.admin.store.products.filter_apply')}</FabButton>
            </div>
          </AccordionItem>

          <AccordionItem id={2}
            isOpen={accordion[2]}
            onChange={handleAccordion}
            label={t('app.admin.store.products.filter_keywords_reference')}
          >
            <div className="content">
              <div className="group">
                <input type="text" onChange={event => handleKeyword(event)} />
                <FabButton onClick={() => setUpdate(true)} className="is-info">{t('app.admin.store.products.filter_apply')}</FabButton>
              </div>
            </div>
          </AccordionItem>

          <AccordionItem id={3}
            isOpen={accordion[3]}
            onChange={handleAccordion}
            label={t('app.admin.store.products.filter_stock')}
          >
            <div className="content">
              <div className="group">
                <FormSelect id="stock_type"
                            options={buildStockOptions()}
                            valueDefault={0}
                            control={control}
                />
                <div className='range'>
                  <FormInput id="stock_from"
                             label={t('app.admin.store.products.filter_stock_from')}
                             register={register}
                             defaultValue={filters.stock_from}
                             type="number" />
                  <FormInput id="stock_to"
                             label={t('app.admin.store.products.filter_stock_to')}
                             register={register}
                             defaultValue={filters.stock_to}
                             type="number" />
                </div>
                <FabButton onClick={handleStockRange} className="is-info">{t('app.admin.store.products.filter_apply')}</FabButton>
              </div>
            </div>
          </AccordionItem>
        </div>
      </aside>
      <div className='store-list'>
        <StoreListHeader
          productsCount={filteredProductsList.length}
          selectOptions={buildSortOptions()}
          onSelectOptionsChange={handleSorting}
          switchChecked={filterVisible}
          onSwitch={toggleVisible}
        />
        <div className='features'>
          {features.categories.map(c => (
            <div key={c.id} className='features-item'>
              <p>{c.name}</p>
              <button onClick={() => handleSelectCategory(c, false, true)}><X size={16} weight="light" /></button>
            </div>
          ))}
          {features.machines.map(m => (
            <div key={m.value} className='features-item'>
              <p>{m.label}</p>
              <button onClick={() => handleSelectMachine(m, false, true)}><X size={16} weight="light" /></button>
            </div>
          ))}
        </div>

        <div className="products-list">
          {filteredProductsList.map((product) => (
            <ProductItem
              key={product.id}
              product={product}
              onEdit={editProduct}
              onDelete={deleteProduct}
            />
          ))}
        </div>
        {pageCount > 1 &&
          <FabPagination pageCount={pageCount} currentPage={currentPage} selectPage={handlePagination} />
        }
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

/** Option format, expected by checklist */
type checklistOption = { value: number, label: string };

/** Convert the provided array of items to the checklist format */
const buildChecklistOptions = (items: Array<{ id?: number, name: string }>): Array<checklistOption> => {
  return items.map(t => {
    return { value: t.id, label: t.name };
  });
};

interface Filters {
  categories: ProductCategory[],
  machines: checklistOption[],
  keywords: string[],
  stock_type: 'internal' | 'external',
  stock_from: number,
  stock_to: number
}

const initFilters: Filters = {
  categories: [],
  machines: [],
  keywords: [],
  stock_type: 'internal',
  stock_from: 0,
  stock_to: 0
};
