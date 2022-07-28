import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ProductCategory } from '../../../models/product-category';
import ProductCategoryAPI from '../../../api/product-category';
import { ManageProductCategory } from './manage-product-category';
import { ProductCategoriesTree } from './product-categories-tree';
import { FabAlert } from '../../base/fab-alert';
import { FabButton } from '../../base/fab-button';
import { HtmlTranslate } from '../../base/html-translate';
import { IApplication } from '../../../models/application';
import { Loader } from '../../base/loader';
import { react2angular } from 'react2angular';

declare const Application: IApplication;

interface ProductCategoriesProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a tree list of all product categories and offer to manager them
 * by creating, deleting, modifying and reordering each product categories.
 */
const ProductCategories: React.FC<ProductCategoriesProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  // List of all products' categories
  const [productCategories, setProductCategories] = useState<Array<ProductCategory>>([]);

  // load the categories list on component mount
  useEffect(() => {
    refreshCategories();
  }, []);

  /**
   * The creation/edition/deletion was successful.
   * Show the provided message and refresh the list
   */
  const handleSuccess = (message: string): void => {
    onSuccess(message);
    refreshCategories();
  };

  /**
   * Update state after drop
   */
  const handleDnd = (data: ProductCategory[]) => {
    setProductCategories(data);
  };

  /**
   * Refresh the list of categories
   */
  const refreshCategories = () => {
    ProductCategoryAPI.index().then(data => {
      // Translate ProductCategory.position to array index
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
    }).catch((error) => onError(error));
  };

  /**
   * Save list's new order
   */
  const handleSave = () => {
    // TODO: index to position -> send to API
    console.log('save order:', productCategories);
  };

  return (
    <div className='product-categories'>
      <header>
        <h2>{t('app.admin.store.product_categories.title')}</h2>
        <div className='grpBtn'>
          <ManageProductCategory action='create'
            productCategories={productCategories}
            onSuccess={handleSuccess} onError={onError} />
          <FabButton className='saveBtn' onClick={handleSave}>Plop</FabButton>
        </div>
      </header>
      <FabAlert level="warning">
        <HtmlTranslate trKey="app.admin.store.product_categories.info" />
      </FabAlert>
      <ProductCategoriesTree
        productCategories={productCategories}
        onDnd={handleDnd}
        onSuccess={handleSuccess} onError={onError} />
    </div>
  );
};

const ProductCategoriesWrapper: React.FC<ProductCategoriesProps> = ({ onSuccess, onError }) => {
  return (
    <Loader>
      <ProductCategories onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};

Application.Components.component('productCategories', react2angular(ProductCategoriesWrapper, ['onSuccess', 'onError']));
