import React, { useState, useEffect } from 'react';
import { useImmer } from 'use-immer';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { Product, ProductIndexFilter, ProductsIndex, ProductSortOption } from '../../models/product';
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
import ProductCategoryAPI from '../../api/product-category';
import ProductLib from '../../lib/product';
import { ActiveFiltersTags } from './filters/active-filters-tags';

declare const Application: IApplication;

interface ProductsProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}
/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
 type selectOption = { value: ProductSortOption, label: string };

/** This component shows the admin view of the store */
const Products: React.FC<ProductsProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [productCategories, setProductCategories] = useState<Array<ProductCategory>>([]);
  const [productsList, setProductList] = useState<Array<Product>>([]);
  const [filters, setFilters] = useImmer<ProductIndexFilter>(initFilters);
  const [pageCount, setPageCount] = useState<number>(0);
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [productsCount, setProductsCount] = useState<number>(0);

  useEffect(() => {
    fetchProducts().then(scrollToProducts);
    ProductCategoryAPI.index().then(data => {
      setProductCategories(ProductLib.sortCategories(data));
    }).catch(onError);
  }, []);

  useEffect(() => {
    fetchProducts().then(scrollToProducts);
  }, [filters]);

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
      setProductList(data.data);
      setPageCount(data.total_pages);
      setProductsCount(data.total_count);
      return data;
    } catch (error) {
      onError(t('app.admin.store.products.unexpected_error_occurred') + error);
    }
  };

  /**
   * Scroll the view to the product list
   */
  const scrollToProducts = () => {
    window.document.getElementById('content-main').scrollTo({ top: 100, behavior: 'smooth' });
  };

  /** Goto edit product page */
  const editProduct = (product: Product) => {
    window.location.href = `/#!/admin/store/products/${product.id}/edit`;
  };

  /** Delete a product */
  const deleteProduct = async (productId: number): Promise<void> => {
    try {
      await ProductAPI.destroy(productId);
      await fetchProducts();
      scrollToProducts();
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
    setFilters(draft => {
      return { ...draft, is_active: checked };
    });
  };

  /**
   * Update the list of applied filters with the given categories
   */
  const handleCategoriesFilterUpdate = (categories: Array<ProductCategory>) => {
    setFilters(draft => {
      return { ...draft, categories };
    });
  };

  /**
   * Remove the provided category from the filters selection
   */
  const handleRemoveCategory = (category: ProductCategory) => {
    const list = ProductLib.categoriesSelectionTree(productCategories, filters.categories, category, 'remove');
    handleCategoriesFilterUpdate(list);
  };

  /**
   * Update the list of applied filters with the given machines
   */
  const handleMachinesFilterUpdate = (machines: Array<Machine>) => {
    setFilters(draft => {
      return { ...draft, machines };
    });
  };

  /**
   * Update the list of applied filters with the given keywords (or reference)
   */
  const handleKeywordFilterUpdate = (keywords: Array<string>) => {
    setFilters(draft => {
      return { ...draft, keywords };
    });
  };

  /** Filter: by stock range */
  const handleStockFilterUpdate = (filters: ProductIndexFilter) => {
    setFilters(draft => {
      return {
        ...draft,
        ...filters
      };
    });
  };

  /** Display option: sorting */
  const handleSorting = (option: selectOption) => {
    setFilters(draft => {
      return {
        ...draft,
        sort: option.value
      };
    });
  };

  /** Clear filters */
  const clearAllFilters = () => {
    setFilters(initFilters);
  };

  /** Creates sorting options to the react-select format */
  const buildSortOptions = (): Array<selectOption> => {
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
      <div className='store-filters'>
        <header>
          <h3>{t('app.admin.store.products.filter')}</h3>
          <div className='grpBtn'>
            <FabButton onClick={clearAllFilters} className="is-black">{t('app.admin.store.products.filter_clear')}</FabButton>
          </div>
        </header>
        <div className='accordion'>
          <CategoriesFilter productCategories={productCategories}
                            onApplyFilters={handleCategoriesFilterUpdate}
                            currentFilters={filters.categories} />

          <MachinesFilter onError={onError}
                          onApplyFilters={handleMachinesFilterUpdate}
                          currentFilters={filters.machines} />

          <KeywordFilter onApplyFilters={keyword => handleKeywordFilterUpdate([keyword])}
                         currentFilters={filters.keywords[0]} />

          <StockFilter onApplyFilters={handleStockFilterUpdate}
                       currentFilters={filters} />
        </div>
      </div>
      <div className='store-list'>
        <StoreListHeader
          productsCount={productsCount}
          selectOptions={buildSortOptions()}
          onSelectOptionsChange={handleSorting}
          switchChecked={filters.is_active}
          onSwitch={toggleVisible}
        />
        <div className='features'>
          <ActiveFiltersTags filters={filters}
                             onRemoveCategory={handleRemoveCategory}
                             onRemoveMachine={(m) => handleMachinesFilterUpdate(filters.machines.filter(machine => machine !== m))}
                             onRemoveKeyword={() => handleKeywordFilterUpdate([])}
                             onRemoveStock={() => handleStockFilterUpdate({ stock_type: 'internal', stock_to: 0, stock_from: 0 })} />
        </div>

        <div className="products-list">
          {productsList.map((product) => (
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

const initFilters: ProductIndexFilter = {
  categories: [],
  machines: [],
  keywords: [],
  stock_type: 'internal',
  stock_from: 0,
  stock_to: 0,
  is_active: false,
  page: 1,
  sort: ''
};
