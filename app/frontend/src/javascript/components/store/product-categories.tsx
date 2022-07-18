import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ProductCategory } from '../../models/product-category';
import ProductCategoryAPI from '../../api/product-category';
import { ManageProductCategory } from './manage-product-category';
import { ProductCategoriesList } from './product-categories-list';
import { FabAlert } from '../base/fab-alert';
import { HtmlTranslate } from '../base/html-translate';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';

declare const Application: IApplication;

interface ProductCategoriesProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a list of all product categories and offer to manager them
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
   * Refresh the list of categories
   */
  const refreshCategories = () => {
    ProductCategoryAPI.index().then(data => {
      setProductCategories(data);
    }).catch((error) => onError(error));
  };

  return (
    <div className='product-categories'>
      <header>
        <h2>{t('app.admin.store.product_categories.title')}</h2>
        <ManageProductCategory action='create'
          productCategories={productCategories}
          onSuccess={handleSuccess} onError={onError} />
      </header>
      <FabAlert level="warning">
        <HtmlTranslate trKey="app.admin.store.product_categories.info" />
      </FabAlert>
      <ProductCategoriesList
        productCategories={productCategories}
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
