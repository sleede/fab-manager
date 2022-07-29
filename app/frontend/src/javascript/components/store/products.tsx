import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
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

  useEffect(() => {
    ProductAPI.index().then(data => {
      setProducts(data);
    });
  }, []);

  /**
   * Goto edit product page
   */
  const editProduct = (product: Product) => {
    window.location.href = `/#!/admin/store/products/${product.id}/edit`;
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

  /**
   * Goto new product page
   */
  const newProduct = (): void => {
    window.location.href = '/#!/admin/store/products/new';
  };

  return (
    <div className='products'>
      <header>
        <h2>{t('app.admin.store.products.all_products')}</h2>
        <div className='grpBtn'>
          <FabButton className="main-action-btn" onClick={newProduct}>{t('app.admin.store.products.create_a_product')}</FabButton>
        </div>
      </header>
      <div className='layout'>
        <div className='products-filters span-3'>
          <header>
            <h3>Filtrer</h3>
            <div className='grpBtn'>
            <FabButton className="is-black">Clear</FabButton>
            </div>
          </header>
        </div>
        <div className='products-list span-7'>
          <div className='status'>
            <div className='count'>
              <p>Result count: <span>{products.length}</span></p>
            </div>
            <div className="">
              <div className='sort'>
                <p>Display options:</p>
              </div>
              <div className='visibility'>

              </div>
            </div>
          </div>
          <div className='features'>
            <div className='features-item'>
              <p>feature name</p>
              <button><i className="fa fa-times" /></button>
            </div>
            <div className='features-item'>
              <p>long feature name</p>
              <button><i className="fa fa-times" /></button>
            </div>
          </div>
          <ProductsList
            products={products}
            onEdit={editProduct}
            onDelete={deleteProduct}
          />
        </div>
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
