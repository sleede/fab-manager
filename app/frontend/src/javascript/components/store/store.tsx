import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { FabButton } from '../base/fab-button';
import { Product, ProductIndexFilter, ProductsIndex, ProductSortOption } from '../../models/product';
import { ProductCategory } from '../../models/product-category';
import ProductAPI from '../../api/product';
import ProductCategoryAPI from '../../api/product-category';
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

declare const Application: IApplication;

interface StoreProps {
  onError: (message: string) => void,
  onSuccess: (message: string) => void,
  currentUser: User,
  uiRouter: UIRouter,
}
/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
 type selectOption = { value: ProductSortOption, label: string };

/**
 * This component shows public store
 */
const Store: React.FC<StoreProps> = ({ onError, onSuccess, currentUser, uiRouter }) => {
  const { t } = useTranslation('public');

  const { cart, setCart } = useCart(currentUser);

  const [products, setProducts] = useState<Array<Product>>([]);
  const [productCategories, setProductCategories] = useState<ProductCategory[]>([]);
  const [categoriesTree, setCategoriesTree] = useState<CategoryTree[]>([]);
  const [pageCount, setPageCount] = useState<number>(0);
  const [productsCount, setProductsCount] = useState<number>(0);
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [filters, setFilters] = useImmer<ProductIndexFilter>(initFilters);

  useEffect(() => {
    // TODO, set the filters in the state
    console.log(ProductLib.readFiltersFromUrl(location.href));
    fetchProducts().then(scrollToProducts);
    ProductCategoryAPI.index().then(data => {
      setProductCategories(data);
      formatCategories(data);
    }).catch(error => {
      onError(t('app.public.store.unexpected_error_occurred') + error);
    });
  }, []);

  useEffect(() => {
    fetchProducts().then(scrollToProducts);
    uiRouter.stateService.transitionTo(uiRouter.globals.current, ProductLib.indexFiltersToRouterParams(filters));
  }, [filters]);

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
    setFilters(draft => {
      return {
        ...draft,
        categories: category
          ? Array.from(new Set([category, ...ProductLib.categoriesSelectionTree(productCategories, [], category, 'add')]))
          : []
      };
    });
  };

  /**
   * Update the list of applied filters with the given machines
   */
  const applyMachineFilters = (machines: Array<Machine>) => {
    setFilters(draft => {
      return { ...draft, machines };
    });
  };

  /**
   * Update the list of applied filters with the given keywords (or reference)
   */
  const applyKeywordFilter = (keywords: Array<string>) => {
    setFilters(draft => {
      return { ...draft, keywords };
    });
  };
  /**
   * Clear filters
   */
  const clearAllFilters = () => {
    setFilters(initFilters);
  };

  /**
   * Creates sorting options to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
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
  const handleSorting = (option: selectOption) => {
    setFilters(draft => {
      return {
        ...draft,
        sort: option.value
      };
    });
  };

  /**
   * Filter: toggle non-available products visibility
   */
  const toggleVisible = (checked: boolean) => {
    setFilters(draft => {
      return { ...draft, is_active: checked };
    });
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
      setFilters(draft => {
        return { ...draft, page };
      });
    }
  };

  /**
  * Fetch the products from the API, according to the current filters
  */
  const fetchProducts = async (): Promise<ProductsIndex> => {
    try {
      const data = await ProductAPI.index(ProductLib.indexFiltersToIds(filters));
      setCurrentPage(data.page);
      setProducts(data.data);
      setPageCount(data.total_pages);
      setProductsCount(data.total_count);
      return data;
    } catch (error) {
      onError(t('app.public.store.unexpected_error_occurred') + error);
    }
  };

  /**
   * Scroll the view to the product list
   */
  const scrollToProducts = () => {
    window.document.getElementById('content-main').scrollTo({ top: 100, behavior: 'smooth' });
  };

  const selectedCategory = filters.categories[0];
  const parent = productCategories.find(c => c.id === selectedCategory?.parent_id);
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
      <aside className='store-filters'>
        <div className="categories">
          <header>
            <h3>{t('app.public.store.products.filter_categories')}</h3>
          </header>
          <div className="group u-scrollbar">
            {categoriesTree.map(c =>
              <div key={c.parent.id} className={`parent ${selectedCategory?.id === c.parent.id || selectedCategory?.parent_id === c.parent.id ? 'is-active' : ''}`}>
                <p onClick={() => filterCategory(c.parent)}>
                  {c.parent.name}<span>(count)</span>
                </p>
                {c.children.length > 0 &&
                  <div className='children'>
                    {c.children.map(ch =>
                      <p key={ch.id}
                        className={selectedCategory?.id === ch.id ? 'is-active' : ''}
                        onClick={() => filterCategory(ch)}>
                        {ch.name}<span>(count)</span>
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
          <MachinesFilter onError={onError} onApplyFilters={applyMachineFilters} currentFilters={filters.machines} />
          <KeywordFilter onApplyFilters={keyword => applyKeywordFilter([keyword])} currentFilters={filters.keywords[0]} />
        </div>
      </aside>
      <div className='store-list'>
        <StoreListHeader
          productsCount={productsCount}
          selectOptions={buildOptions()}
          onSelectOptionsChange={handleSorting}
          switchLabel={t('app.public.store.products.in_stock_only')}
          switchChecked={filters.is_active}
          onSwitch={toggleVisible}
        />
        <div className='features'>
          <ActiveFiltersTags filters={filters}
                             displayCategories={false}
                             onRemoveMachine={(m) => applyMachineFilters(filters.machines.filter(machine => machine !== m))}
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

const initFilters: ProductIndexFilter = {
  categories: [],
  keywords: [],
  machines: [],
  is_active: false,
  page: 1,
  sort: ''
};
