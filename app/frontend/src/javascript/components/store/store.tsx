import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { FabButton } from '../base/fab-button';
import { Product } from '../../models/product';
import { ProductCategory } from '../../models/product-category';
import ProductAPI from '../../api/product';
import ProductCategoryAPI from '../../api/product-category';
import MachineAPI from '../../api/machine';
import { StoreProductItem } from './store-product-item';
import useCart from '../../hooks/use-cart';
import { emitCustomEvent } from 'react-custom-events';
import { User } from '../../models/user';
import { AccordionItem } from './accordion-item';
import { ProductsListHeader } from './products-list-header';

declare const Application: IApplication;

interface StoreProps {
  onError: (message: string) => void,
  currentUser: User,
}
/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
 type selectOption = { value: number, label: string };

/**
 * This component shows public store
 */
const Store: React.FC<StoreProps> = ({ onError, currentUser }) => {
  const { t } = useTranslation('public');

  const { cart, setCart } = useCart(currentUser);

  const [products, setProducts] = useState<Array<Product>>([]);
  const [productCategories, setProductCategories] = useState<ProductCategory[]>([]);
  const [categoriesTree, setCategoriesTree] = useState<ParentCategory[]>([]);
  const [activeCategory, setActiveCategory] = useState<ActiveCategory>();
  const [filterVisible, setFilterVisible] = useState<boolean>(false);
  const [machines, setMachines] = useState<checklistOption[]>([]);
  const [accordion, setAccordion] = useState({});

  useEffect(() => {
    ProductAPI.index({ is_active: true }).then(data => {
      setProducts(data);
    }).catch(() => {
      onError(t('app.public.store.unexpected_error_occurred'));
    });

    ProductCategoryAPI.index().then(data => {
      setProductCategories(data);
      formatCategories(data);
    }).catch(() => {
      onError(t('app.public.store.unexpected_error_occurred'));
    });

    MachineAPI.index({ disabled: false }).then(data => {
      setMachines(buildChecklistOptions(data));
    }).catch(() => {
      onError(t('app.public.store.unexpected_error_occurred'));
    });
  }, []);

  useEffect(() => {
    emitCustomEvent('CartUpdate', cart);
  }, [cart]);

  useEffect(() => {
    if (currentUser) {
      reloadCart();
    }
  }, [currentUser]);

  /**
   * Create categories tree (parent/children)
   */
  const formatCategories = (list: ProductCategory[]) => {
    const tree = [];
    const parents = list.filter(c => !c.parent_id);
    const getChildren = (id) => {
      return list.filter(c => c.parent_id === id);
    };
    parents.forEach(p => {
      tree.push({ parent: p, children: getChildren(p.id) });
    });
    setCategoriesTree(tree);
  };

  /**
   * Filter by category
   */
  const filterCategory = (id: number, parent?: number) => {
    setActiveCategory({ id, parent });
    console.log('Filter by category:', productCategories.find(c => c.id === id).name);
  };

  /**
   * Apply filters
   */
  const applyFilters = () => {
    console.log('Filter products');
  };
  /**
   * Clear filters
   */
  const clearAllFilters = () => {
    console.log('Clear filters');
  };

  /**
   * Open/close accordion items
   */
  const handleAccordion = (id, state) => {
    setAccordion({ ...accordion, [id]: state });
  };

  /**
   * Creates sorting options to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return [
      { value: 0, label: t('app.public.store.products.sort.name_az') },
      { value: 1, label: t('app.public.store.products.sort.name_za') },
      { value: 2, label: t('app.public.store.products.sort.price_low') },
      { value: 3, label: t('app.public.store.products.sort.price_high') }
    ];
  };
  /**
   * Display option: sorting
   */
  const handleSorting = (option: selectOption) => {
    console.log('Sort option:', option);
  };

  /**
   * Filter: toggle non-available products visibility
   */
  const toggleVisible = (checked: boolean) => {
    setFilterVisible(!filterVisible);
    console.log('Display in stock only:', checked);
  };

  return (
    <div className="store">
      <ul className="breadcrumbs">
        <li>
          <span onClick={() => setActiveCategory(null)}>{t('app.public.store.products.all_products')}</span>
        </li>
        {activeCategory?.parent &&
          <li>
            <span onClick={() => filterCategory(activeCategory?.parent)}>
              {productCategories.find(c => c.id === activeCategory.parent).name}
            </span>
          </li>
        }
        {activeCategory?.id &&
          <li>
            <span onClick={() => filterCategory(activeCategory?.id, activeCategory?.parent)}>
              {productCategories.find(c => c.id === activeCategory.id).name}
            </span>
          </li>
        }
      </ul>
      <aside className='store-filters'>
        <div className="categories">
          <header>
            <h3>{t('app.public.store.products.filter_categories')}</h3>
          </header>
          <div className="list u-scrollbar">
            {categoriesTree.map(c =>
              <div key={c.parent.id} className={`parent ${activeCategory?.id === c.parent.id || activeCategory?.parent === c.parent.id ? 'is-active' : ''}`}>
                <p onClick={() => filterCategory(c.parent.id)}>
                  {c.parent.name}<span>(count)</span>
                </p>
                {c.children.length > 0 &&
                  <div className='children'>
                    {c.children.map(ch =>
                      <p key={ch.id}
                        className={activeCategory?.id === ch.id ? 'is-active' : ''}
                        onClick={() => filterCategory(ch.id, c.parent.id)}>
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
          <div className="accordion">
            <AccordionItem id={1}
              isOpen={accordion[1]}
              onChange={handleAccordion}
              label={t('app.public.store.products.filter_machines')}
            >
              <div className='content'>
                <div className="list u-scrollbar">
                  {machines.map(m => (
                    <label key={m.value}>
                      <input type="checkbox" />
                      <p>{m.label}</p>
                    </label>
                  ))}
                </div>
                <FabButton onClick={applyFilters} className="is-info">{t('app.public.store.products.filter_apply')}</FabButton>
              </div>
            </AccordionItem>
          </div>
        </div>
      </aside>
      <div className='store-products-list'>
        <ProductsListHeader
          productsCount={products.length}
          selectOptions={buildOptions()}
          onSelectOptionsChange={handleSorting}
          switchLabel={t('app.public.store.products.in_stock_only')}
          switchChecked={filterVisible}
          onSwitch={toggleVisible}
        />
        <div className="products-grid">
          {products.map((product) => (
            <StoreProductItem key={product.id} product={product} cart={cart} onSuccessAddProductToCart={setCart} />
          ))}
        </div>
      </div>
    </div>
  );
};

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

const StoreWrapper: React.FC<StoreProps> = (props) => {
  return (
    <Loader>
      <Store {...props} />
    </Loader>
  );
};

Application.Components.component('store', react2angular(StoreWrapper, ['onError', 'currentUser']));

interface ActiveCategory {
  id: number,
  parent: number
}
interface ParentCategory {
  parent: ProductCategory,
  children: ProductCategory[]
}
