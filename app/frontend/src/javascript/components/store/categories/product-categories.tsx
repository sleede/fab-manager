import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ProductCategory } from '../../../models/product-category';
import ProductCategoryAPI from '../../../api/product-category';
import { ManageProductCategory } from './manage-product-category';
import { ProductCategoriesTree } from './product-categories-tree';
import { FabAlert } from '../../base/fab-alert';
import { HtmlTranslate } from '../../base/html-translate';
import { IApplication } from '../../../models/application';
import { Loader } from '../../base/loader';
import { react2angular } from 'react2angular';
import ProductLib from '../../../lib/product';

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
  const handleDnd = (list: ProductCategory[], activeCategory: ProductCategory, position: number) => {
    setProductCategories(list);
    ProductCategoryAPI
      .update(activeCategory)
      .then(c => {
        ProductCategoryAPI
          .updatePosition(c, position)
          .then(refreshCategories)
          .catch(error => onError(error));
      })
      .catch(error => onError(error));
  };

  /**
   * Refresh the list of categories
   */
  const refreshCategories = () => {
    ProductCategoryAPI.index().then(data => {
      setProductCategories(ProductLib.sortCategories(data));
    }).catch((error) => onError(error));
  };

  return (
    <div className='product-categories'>
      <header>
        <h2>{t('app.admin.store.product_categories.title')}</h2>
        <div className='grpBtn'>
          <ManageProductCategory action='create'
            productCategories={productCategories}
            onSuccess={handleSuccess} onError={onError} />
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
