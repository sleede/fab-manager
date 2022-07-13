import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { HtmlTranslate } from '../base/html-translate';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { FabAlert } from '../base/fab-alert';
import { FabButton } from '../base/fab-button';
import { ProductsList } from './products-list';
import { Product } from '../../models/product';
import ProductAPI from '../../api/product';

declare const Application: IApplication;

interface ProductsProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows all Products and filter
 */
const Products: React.FC<ProductsProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [products, setProducts] = useState<Array<Product>>([]);
  const [product, setProduct] = useState<Product>(null);

  useEffect(() => {
    ProductAPI.index().then(data => {
      setProducts(data);
    });
  }, []);

  /**
   * Open edit the product modal
   */
  const editProduct = (product: Product) => {
    setProduct(product);
  };

  /**
   * Delete a product
   */
  const deleteProduct = async (productId: number): Promise<void> => {
    try {
      await ProductAPI.destroy(productId);
      const data = await ProductAPI.index();
      setProducts(data);
      onSuccess(t('app.admin.store.products.successfully_deleted'));
    } catch (e) {
      onError(t('app.admin.store.products.unable_to_delete') + e);
    }
  };

  return (
    <div>
      <h2>{t('app.admin.store.products.all_products')}</h2>
      <FabButton className="save">{t('app.admin.store.products.create_a_product')}</FabButton>
      <ProductsList
        products={products}
        onEdit={editProduct}
        onDelete={deleteProduct}
      />
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
