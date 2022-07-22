import React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { ProductForm } from './product-form';

declare const Application: IApplication;

interface NewProductProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component show new product form
 */
const NewProduct: React.FC<NewProductProps> = ({ onSuccess, onError }) => {
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
    machine_ids: []
  };

  /**
   * Success to save product and return to product list
   */
  const saveProductSuccess = () => {
    onSuccess(t('app.admin.store.new_product.successfully_created'));
    window.location.href = '/#!/admin/store/products';
  };

  return (
    <ProductForm product={product} title={t('app.admin.store.new_product.add_a_new_product')} onSuccess={saveProductSuccess} onError={onError} />
  );
};

const NewProductWrapper: React.FC<NewProductProps> = ({ onSuccess, onError }) => {
  return (
    <Loader>
      <NewProduct onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};

Application.Components.component('newProduct', react2angular(NewProductWrapper, ['onSuccess', 'onError']));
