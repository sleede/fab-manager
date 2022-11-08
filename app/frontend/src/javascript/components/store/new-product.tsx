import React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { ProductForm } from './product-form';
import { UIRouter } from '@uirouter/angularjs';

declare const Application: IApplication;

interface NewProductProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  uiRouter: UIRouter,
}

/**
 * This component show new product form
 */
const NewProduct: React.FC<NewProductProps> = ({ onSuccess, onError, uiRouter }) => {
  const { t } = useTranslation('admin');

  const product = {
    id: undefined,
    name: '',
    slug: '',
    sku: '',
    description: '',
    is_active: false,
    quantity_min: 1,
    stock: {
      internal: 0,
      external: 0
    },
    low_stock_alert: false,
    machine_ids: [],
    product_files_attributes: [],
    product_images_attributes: []
  };

  /**
   * Success to save product and return to product list
   */
  const saveProductSuccess = () => {
    onSuccess(t('app.admin.store.new_product.successfully_created'));
    window.location.href = '/#!/admin/store/products';
  };

  return (
    <div className="new-product">
      <ProductForm product={product}
                   title={t('app.admin.store.new_product.add_a_new_product')}
                   onSuccess={saveProductSuccess}
                   onError={onError}
                   uiRouter={uiRouter} />
    </div>
  );
};

const NewProductWrapper: React.FC<NewProductProps> = (props) => {
  return (
    <Loader>
      <NewProduct {...props} />
    </Loader>
  );
};

Application.Components.component('newProduct', react2angular(NewProductWrapper, ['onSuccess', 'onError', 'uiRouter']));
