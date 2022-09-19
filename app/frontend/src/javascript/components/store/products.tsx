import React, { useState, useEffect } from 'react';
import { useImmer } from 'use-immer';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { Product } from '../../models/product';
import { ProductCategory } from '../../models/product-category';
import { FabButton } from '../base/fab-button';
import { ProductItem } from './product-item';
import ProductAPI from '../../api/product';
import { X } from 'phosphor-react';
import { StoreListHeader } from './store-list-header';
import { FabPagination } from '../base/fab-pagination';
import { CategoriesFilter } from './filters/categories-filter';
import { Machine } from '../../models/machine';
import { MachinesFilter } from './filters/machines-filter';
import { KeywordFilter } from './filters/keyword-filter';
import { StockFilter, StockFilterData } from './filters/stock-filter';

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

  const [filteredProductsList, setFilteredProductList] = useImmer<Array<Product>>([]);
  const [features, setFeatures] = useImmer<Filters>(initFilters);
  const [filterVisible, setFilterVisible] = useState<boolean>(false);
  const [filters, setFilters] = useImmer<Filters>(initFilters);
  const [clearFilters, setClearFilters] = useState<boolean>(false);
  const [update, setUpdate] = useState(false);
  const [pageCount, setPageCount] = useState<number>(0);
  const [currentPage, setCurrentPage] = useState<number>(1);

  useEffect(() => {
    ProductAPI.index({ page: 1, is_active: filterVisible }).then(data => {
      setPageCount(data.total_pages);
      setFilteredProductList(data.products);
    });
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

  /**
   * Update the list of applied filters with the given categories
   */
  const handleCategoriesFilterUpdate = (categories: Array<ProductCategory>) => {
    setFilters(draft => {
      return { ...draft, categories };
    });
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
  const handleStockFilterUpdate = (filters: StockFilterData) => {
    setFilters(draft => {
      return {
        ...draft,
        ...filters
      };
    });
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
          <CategoriesFilter onError={onError}
                            onApplyFilters={handleCategoriesFilterUpdate}
                            currentFilters={filters.categories} />

          <MachinesFilter onError={onError}
                          onApplyFilters={handleMachinesFilterUpdate}
                          currentFilters={filters.machines} />

          <KeywordFilter onApplyFilters={keyword => handleKeywordFilterUpdate([...filters.keywords, keyword])}
                         currentFilters={filters.keywords[0]} />

          <StockFilter onApplyFilters={handleStockFilterUpdate}
                       currentFilters={filters} />
        </div>
      </div>
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
              <button onClick={() => handleCategoriesFilterUpdate(filters.categories.filter(cat => cat !== c))}><X size={16} weight="light" /></button>
            </div>
          ))}
          {features.machines.map(m => (
            <div key={m.id} className='features-item'>
              <p>{m.name}</p>
              <button onClick={() => handleMachinesFilterUpdate(filters.machines.filter(machine => machine !== m))}><X size={16} weight="light" /></button>
            </div>
          ))}
          {features.keywords.map(k => (
            <div key={k} className='features-item'>
              <p>{k}</p>
              <button onClick={() => handleKeywordFilterUpdate(filters.keywords.filter(keyword => keyword !== k))}><X size={16} weight="light" /></button>
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

interface Filters {
  categories: ProductCategory[],
  machines: Machine[],
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
