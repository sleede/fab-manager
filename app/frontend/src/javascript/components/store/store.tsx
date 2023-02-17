import { useState, useEffect } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { FabButton } from '../base/fab-button';
import {
  initialFilters,
  initialResources,
  Product,
  ProductResourcesFetching,
  ProductsIndex,
  ProductSortOption
} from '../../models/product';
import { ProductCategory } from '../../models/product-category';
import ProductAPI from '../../api/product';
import { StoreProductItem } from './store-product-item';
import useCart from '../../hooks/use-cart';
import { User } from '../../models/user';
import { Order } from '../../models/order';
import { StoreListHeader } from './store-list-header';
import { FabPagination } from '../base/fab-pagination';
import { MachinesFilter } from './filters/machines-filter';
import { useImmer } from 'use-immer';
import { Machine } from '../../models/machine';
import { KeywordFilter } from './filters/keyword-filter';
import { ActiveFiltersTags } from './filters/active-filters-tags';
import ProductLib from '../../lib/product';
import { UIRouter } from '@uirouter/angularjs';
import SettingAPI from '../../api/setting';
import { SelectOption } from '../../models/select';
import { CaretDoubleUp } from 'phosphor-react';

declare const Application: IApplication;

const storeInitialFilters = {
  ...initialFilters,
  is_active: true
};

const storeInitialResources = {
  ...initialResources,
  filters: {
    data: storeInitialFilters,
    ready: false
  }
};

interface StoreProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  currentUser: User,
  uiRouter: UIRouter,
}

/**
 * This component shows public store
 */
const Store: React.FC<StoreProps> = ({ onError, onSuccess, currentUser, uiRouter }) => {
  const { t } = useTranslation('public');

  const { cart, setCart } = useCart(currentUser);

  const [products, setProducts] = useState<Array<Product>>([]);
  // this includes the resources fetch from the API (machines, categories) and from the URL (filters)
  const [resources, setResources] = useImmer<ProductResourcesFetching>(storeInitialResources);
  const [machinesModule, setMachinesModule] = useState<boolean>(false);
  const [categoriesTree, setCategoriesTree] = useState<CategoryTree[]>([]);
  const [filtersPanel, setFiltersPanel] = useState<boolean>(false);
  const [pageCount, setPageCount] = useState<number>(0);
  const [productsCount, setProductsCount] = useState<number>(0);
  const [currentPage, setCurrentPage] = useState<number>(1);

  useEffect(() => {
    ProductLib.fetchInitialResources(setResources, onError, formatCategories);
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
            data: ProductLib.readFiltersFromUrl(uiRouter.globals.params, resources.machines.data, resources.categories.data, storeInitialFilters),
            ready: true
          }
        };
      });
    }
  }, [resources.machines, resources.categories]);

  /**
   * Create categories tree (parent/children)
   */
  const formatCategories = (list: ProductCategory[]) => {
    const tree: Array<CategoryTree> = [];
    const parents = list.filter(c => !c.parent_id);
    parents.forEach(p => {
      tree.push({
        parent: p,
        children: list.filter(c => c.parent_id === p.id)
      });
    });
    setCategoriesTree(tree);
  };

  /**
   * Filter by category: the selected category will always be first
   */
  const filterCategory = (category: ProductCategory) => {
    ProductLib.updateFilter(
      setResources,
      'categories',
      category
        ? Array.from(new Set([category, ...ProductLib.categoriesSelectionTree(resources.categories.data, [], category, 'add')]))
        : []
    );
  };

  /**
   * Update the list of applied filters with the given machines
   */
  const applyMachineFilters = (machines: Array<Machine>) => {
    ProductLib.updateFilter(setResources, 'machines', machines);
  };

  /**
   * Update the list of applied filters with the given keywords (or reference)
   */
  const applyKeywordFilter = (keywords: Array<string>) => {
    ProductLib.updateFilter(setResources, 'keywords', keywords);
  };
  /**
   * Clear filters
   */
  const clearAllFilters = () => {
    setResources(draft => {
      return {
        ...draft,
        filters: {
          ...draft.filters,
          data: {
            ...storeInitialFilters,
            categories: draft.filters.data.categories
          }
        }
      };
    });
  };

  /**
   * Creates sorting options to the react-select format
   */
  const buildOptions = (): Array<SelectOption<ProductSortOption>> => {
    return [
      { value: 'name-asc', label: t('app.public.store.products.sort.name_az') },
      { value: 'name-desc', label: t('app.public.store.products.sort.name_za') },
      { value: 'amount-asc', label: t('app.public.store.products.sort.price_low') },
      { value: 'amount-desc', label: t('app.public.store.products.sort.price_high') }
    ];
  };
  /**
   * Display option: sorting
   */
  const handleSorting = (option: SelectOption<ProductSortOption>) => {
    ProductLib.updateFilter(setResources, 'sort', option.value);
  };

  /**
   * Filter: toggle non-available products visibility
   */
  const toggleVisible = (checked: boolean) => {
    ProductLib.updateFilter(setResources, 'is_available', checked);
  };

  /**
   * Add product to the cart
   */
  const addToCart = (cart: Order) => {
    setCart(cart);
    onSuccess(t('app.public.store.add_to_cart_success'));
  };

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
      const data = await ProductAPI.index(Object.assign({ store: true }, resources.filters.data));
      setCurrentPage(data.page);
      setProducts(data.data);
      setPageCount(data.total_pages);
      setProductsCount(data.total_count);
      return data;
    } catch (error) {
      onError(t('app.public.store.unexpected_error_occurred') + error);
    }
  };

  const selectedCategory = resources.filters.data.categories[0];
  const parent = resources.categories.data.find(c => c.id === selectedCategory?.parent_id);
  return (
    <div className="store">
      <ul className="breadcrumbs">
        <li>
          <span onClick={() => filterCategory(null)}>{t('app.public.store.products.all_products')}</span>
        </li>
        {parent &&
          <li>
            <span onClick={() => filterCategory(parent)}>
              {parent.name}
            </span>
          </li>
          }
        {selectedCategory &&
          <li>
            <span onClick={() => filterCategory(selectedCategory)}>
              {selectedCategory.name}
            </span>
          </li>
        }
      </ul>
      <aside className={`store-filters ${filtersPanel ? '' : 'collapsed'}`}>
        <header>
          <h3>{t('app.public.store.products.filter_categories')}</h3>
          <div className="grpBtn">
            <CaretDoubleUp className='filters-toggle' size={16} weight="bold" onClick={() => setFiltersPanel(!filtersPanel)} />
          </div>
        </header>
        <div className='grp'>
          <div className="categories">
            <div className="group u-scrollbar">
              {categoriesTree.map(c =>
                <div key={c.parent.id} className={`parent ${selectedCategory?.id === c.parent.id || selectedCategory?.parent_id === c.parent.id ? 'is-active' : ''}`}>
                  <p onClick={() => filterCategory(c.parent)}>
                    {c.parent.name}
                    <span>
                      {/* here we add the parent count with the sum of all children counts */}
                      {
                        c.parent.products_count +
                        c.children
                          .map(ch => ch.products_count)
                          .reduce((sum, val) => sum + val, 0)
                      }
                    </span>
                  </p>
                  {c.children.length > 0 &&
                    <div className='children'>
                      {c.children.map(ch =>
                        <p key={ch.id}
                          className={selectedCategory?.id === ch.id ? 'is-active' : ''}
                          onClick={() => filterCategory(ch)}>
                          {ch.name}<span>{ch.products_count}</span>
                        </p>
                      )}
                    </div>
                  }
                </div>
              )}
            </div>
          </div>
          <div className='filters'>
            <header>
              <h3>{t('app.public.store.products.filter')}</h3>
              <div className='grpBtn'>
                <FabButton onClick={clearAllFilters} className="is-black">{t('app.public.store.products.filter_clear')}</FabButton>
              </div>
            </header>
            {machinesModule && resources.machines.ready &&
              <MachinesFilter allMachines={resources.machines.data}
                              onError={onError}
                              onApplyFilters={applyMachineFilters}
                              currentFilters={resources.filters.data.machines} />
            }
            <KeywordFilter onApplyFilters={keyword => applyKeywordFilter([keyword])} currentFilters={resources.filters.data.keywords[0]} />
          </div>
        </div>
      </aside>
      <div className='store-list'>
        <StoreListHeader
          productsCount={productsCount}
          selectOptions={buildOptions()}
          onSelectOptionsChange={handleSorting}
          switchLabel={t('app.public.store.products.in_stock_only')}
          switchChecked={resources.filters.data.is_available}
          selectValue={resources.filters.data.sort}
          onSwitch={toggleVisible}
        />
        <div className='features'>
          <ActiveFiltersTags filters={resources.filters.data}
                             displayCategories={false}
                             onRemoveMachine={(m) => applyMachineFilters(resources.filters.data.machines.filter(machine => machine !== m))}
                             onRemoveKeyword={() => applyKeywordFilter([])} />
        </div>
        <div className="products-grid">
          {products.map((product) => (
            <StoreProductItem key={product.id} product={product} cart={cart} onSuccessAddProductToCart={addToCart} onError={onError} />
          ))}
        </div>
        {pageCount > 1 &&
          <FabPagination pageCount={pageCount} currentPage={currentPage} selectPage={handlePagination} />
        }
      </div>
    </div>
  );
};

const StoreWrapper: React.FC<StoreProps> = (props) => {
  return (
    <Loader>
      <Store {...props} />
    </Loader>
  );
};

Application.Components.component('store', react2angular(StoreWrapper, ['onError', 'onSuccess', 'currentUser', 'uiRouter']));

interface CategoryTree {
  parent: ProductCategory,
  children: ProductCategory[]
}
