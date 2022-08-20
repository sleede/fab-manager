import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { FabButton } from '../base/fab-button';
import { Product } from '../../models/product';
import ProductAPI from '../../api/product';
import { StoreProductItem } from './store-product-item';
import useCart from '../../hooks/use-cart';
import { emitCustomEvent } from 'react-custom-events';

declare const Application: IApplication;

interface StoreProps {
  onError: (message: string) => void,
}

/**
 * This component shows public store
 */
const Store: React.FC<StoreProps> = ({ onError }) => {
  const { t } = useTranslation('public');

  const { cart, setCart } = useCart();

  const [products, setProducts] = useState<Array<Product>>([]);

  useEffect(() => {
    ProductAPI.index({ is_active: true }).then(data => {
      setProducts(data);
    }).catch(() => {
      onError(t('app.public.store.unexpected_error_occurred'));
    });
  }, []);

  useEffect(() => {
    emitCustomEvent('CartUpdate', cart);
  }, [cart]);

  return (
    <div className="store">
      <div className='layout'>
        <div className='store-filters span-3'>
          <header>
            <h3>Filtrer</h3>
            <div className='grpBtn'>
            <FabButton className="is-black">Clear</FabButton>
            </div>
          </header>
        </div>
        <div className='store-products-list span-7'>
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

          <div className="products">
            {products.map((product) => (
              <StoreProductItem key={product.id} product={product} cart={cart} onSuccessAddProductToCart={setCart} />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

const StoreWrapper: React.FC<StoreProps> = ({ onError }) => {
  return (
    <Loader>
      <Store onError={onError} />
    </Loader>
  );
};

Application.Components.component('store', react2angular(StoreWrapper, ['onError']));
