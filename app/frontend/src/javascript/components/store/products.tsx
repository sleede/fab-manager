import { useState, useEffect } from 'react';
import * as React from 'react';
import { useImmer } from 'use-immer';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import {
  initialFilters, initialResources,
  Product,
  ProductIndexFilter,
  ProductResourcesFetching,
  ProductsIndex,
  ProductSortOption
} from '../../models/product';
import { ProductCategory } from '../../models/product-category';
import { FabButton } from '../base/fab-button';
import { ProductItem } from './product-item';
import ProductAPI from '../../api/product';
import { StoreListHeader } from './store-list-header';
import { FabPagination } from '../base/fab-pagination';
import { CategoriesFilter } from './filters/categories-filter';
import { Machine } from '../../models/machine';
import { MachinesFilter } from './filters/machines-filter';
import { KeywordFilter } from './filters/keyword-filter';
import { StockFilter } from './filters/stock-filter';
import ProductLib from '../../lib/product';
import { ActiveFiltersTags } from './filters/active-filters-tags';
import SettingAPI from '../../api/setting';
import { UIRouter } from '@uirouter/angularjs';
import { CaretDoubleUp } from 'phosphor-react';
import { SelectOption } from '../../models/select';

declare const Application: IApplication;

interface ProductsProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  uiRouter: UIRouter,
}

/** This component shows the admin view of the store */
const Products: React.FC<ProductsProps> = ({ onSuccess, onError, uiRouter }) => {
  const { t } = useTranslation('admin');

  const [productsList, setProductList] = useState<Array<Product>>([]);
  // this includes the resources fetch from the API (machines, categories) and from the URL (filters)
  const [resources, setResources] = useImmer<ProductResourcesFetching>(initialResources);
  const [machinesModule, setMachinesModule] = useState<boolean>(false);
  const [pageCount, setPageCount] = useState<number>(0);
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [productsCount, setProductsCount] = useState<number>(0);
  const [filtersPanel, setFiltersPanel] = useState<boolean>(true);

  useEffect(() => {
    ProductLib.fetchInitialResources(setResources, onError);
    SettingAPI.get('machines_module').then(data => {
      setMachinesModule(data.value === 'true');
    }).catch(onError);
  }, []);

  useEffect(() => {
    if (resources.filters.ready) {
      fetchProducts();
      uiRouter.stateService.transitionTo(uiRouter.globals.current, ProductLib.indexFiltersToRouterParams(resources.filters.data));
    }
  }, [resources.filters]);

  useEffect(() => {
    if (resources.machines.ready && resources.categories.ready) {
      setResources(draft => {
        return {
          ...draft,
          filters: {
            data: ProductLib.readFiltersFromUrl(uiRouter.globals.params, resources.machines.data, resources.categories.data),
            ready: true
          }
        };
      });
    }
  }, [resources.machines, resources.categories]);

  /**
   * Handle products pagination
   */
  const handlePagination = (page: number) => {
    if (page !== currentPage) {
      ProductLib.updateFilter(setResources, 'page', page);
    }
  };

  /**
   * Fetch the products from the API, according to the current filters
   */
  const fetchProducts = async (): Promise<ProductsIndex> => {
    try {
      const data = await ProductAPI.index(resources.filters.data);
      setCurrentPage(data.page);
      setProductList(data.data);
      setPageCount(data.total_pages);
      setProductsCount(data.total_count);
      return data;
    } catch (error) {
      onError(t('app.admin.store.products.unexpected_error_occurred') + error);
    }
  };

  /** Goto edit product page */
  const editProduct = (product: Product) => {
    window.location.href = `/#!/admin/store/products/${product.id}/edit`;
  };

  /** Delete a product */
  const deleteProduct = async (message: string): Promise<void> => {
    await fetchProducts();
    onSuccess(message);
  };

  /** Goto new product page */
  const newProduct = (): void => {
    window.location.href = '/#!/admin/store/products/new';
  };

  /** Filter: toggle non-available products visibility */
  const toggleVisible = (checked: boolean) => {
    ProductLib.updateFilter(setResources, 'is_active', checked);
  };

  /**
   * Update the list of applied filters with the given categories
   */
  const handleCategoriesFilterUpdate = (categories: Array<ProductCategory>) => {
    ProductLib.updateFilter(setResources, 'categories', categories);
  };

  /**
   * Remove the provided category from the filters selection
   */
  const handleRemoveCategory = (category: ProductCategory) => {
    const list = ProductLib.categoriesSelectionTree(resources.categories.data, resources.filters.data.categories, category, 'remove');
    handleCategoriesFilterUpdate(list);
  };

  /**
   * Update the list of applied filters with the given machines
   */
  const handleMachinesFilterUpdate = (machines: Array<Machine>) => {
    ProductLib.updateFilter(setResources, 'machines', machines);
  };

  /**
   * Update the list of applied filters with the given keywords (or reference)
   */
  const handleKeywordFilterUpdate = (keywords: Array<string>) => {
    ProductLib.updateFilter(setResources, 'keywords', keywords);
  };

  /** Filter: by stock range */
  const handleStockFilterUpdate = (filters: ProductIndexFilter) => {
    setResources(draft => {
      return { ...draft, filters: { ...draft.filters, data: { ...draft.filters.data, ...filters } } };
    });
  };

  /** Display option: sorting */
  const handleSorting = (option: SelectOption<ProductSortOption>) => {
    ProductLib.updateFilter(setResources, 'sort', option.value);
  };

  /** Clear filters */
  const clearAllFilters = () => {
    setResources(draft => {
      return { ...draft, filters: { ...draft.filters, data: initialFilters } };
    });
  };

  /** Creates sorting options to the react-select format */
  const buildSortOptions = (): Array<SelectOption<ProductSortOption>> => {
    return [
      { value: 'name-asc', label: t('app.admin.store.products.sort.name_az') },
      { value: 'name-desc', label: t('app.admin.store.products.sort.name_za') },
      { value: 'amount-asc', label: t('app.admin.store.products.sort.price_low') },
      { value: 'amount-desc', label: t('app.admin.store.products.sort.price_high') }
    ];
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
          <CategoriesFilter productCategories={resources.categories.data}
                            onApplyFilters={handleCategoriesFilterUpdate}
                            currentFilters={resources.filters.data.categories} />

          {machinesModule && <MachinesFilter onError={onError}
                                             allMachines={resources.machines.data}
                                             onApplyFilters={handleMachinesFilterUpdate}
                                             currentFilters={resources.filters.data.machines} />}

          <KeywordFilter onApplyFilters={keyword => handleKeywordFilterUpdate([keyword])}
                         currentFilters={resources.filters.data.keywords[0]} />

          <StockFilter onApplyFilters={handleStockFilterUpdate}
                       currentFilters={resources.filters.data} />
        </div>
      </aside>
      <div className='store-list'>
        <StoreListHeader
          productsCount={productsCount}
          selectOptions={buildSortOptions()}
          onSelectOptionsChange={handleSorting}
          selectValue={resources.filters.data.sort}
          switchChecked={resources.filters.data.is_active}
          onSwitch={toggleVisible}
        />
        <div className='features'>
          <ActiveFiltersTags filters={resources.filters.data}
                             onRemoveCategory={handleRemoveCategory}
                             onRemoveMachine={(m) => handleMachinesFilterUpdate(resources.filters.data.machines.filter(machine => machine !== m))}
                             onRemoveKeyword={() => handleKeywordFilterUpdate([])}
                             onRemoveStock={() => handleStockFilterUpdate({ stock_type: 'internal', stock_to: 0, stock_from: 0 })} />
        </div>

        <div className="products-list">
          {productsList.map((product) => (
            <ProductItem
              key={product.id}
              product={product}
              onError={onError}
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

const ProductsWrapper: React.FC<ProductsProps> = (props) => {
  return (
    <Loader>
      <Products {...props} />
    </Loader>
  );
};

Application.Components.component('products', react2angular(ProductsWrapper, ['onSuccess', 'onError', 'uiRouter']));
