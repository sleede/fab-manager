/* eslint-disable fabmanager/scoped-translation */
import React, { useEffect, useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import FormatLib from '../../lib/format';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import _ from 'lodash';
import { Product } from '../../models/product';
import { User } from '../../models/user';
import ProductAPI from '../../api/product';
import CartAPI from '../../api/cart';
import noImage from '../../../../images/no_image.png';
import { FabButton } from '../base/fab-button';
import useCart from '../../hooks/use-cart';
import { FilePdf, Minus, Plus } from 'phosphor-react';
import { FabStateLabel } from '../base/fab-state-label';

declare const Application: IApplication;

interface StoreProductProps {
  productSlug: string,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  currentUser?: User
}

/**
 * This component shows a product
 */
export const StoreProduct: React.FC<StoreProductProps> = ({ productSlug, currentUser, onSuccess, onError }) => {
  const { t } = useTranslation('public');

  const { cart, setCart } = useCart(currentUser);
  const [product, setProduct] = useState<Product>();
  const [showImage, setShowImage] = useState<number>(null);
  const [toCartCount, setToCartCount] = useState<number>(0);
  const [displayToggle, setDisplayToggle] = useState<boolean>(false);
  const [collapseDescription, setCollapseDescription] = useState<boolean>(true);
  const descContainer = useRef(null);

  useEffect(() => {
    ProductAPI.get(productSlug).then(data => {
      setProduct(data);
      const productImage = _.find(data.product_images_attributes, { is_main: true });
      if (productImage) {
        setShowImage(productImage.id);
      }
      setToCartCount(data.quantity_min ? data.quantity_min : 1);
      setDisplayToggle(descContainer.current.offsetHeight < descContainer.current.scrollHeight);
    }).catch((e) => {
      onError(t('app.public.store_product.unexpected_error_occurred') + e);
    });
  }, []);

  /**
   * Return main image of Product, if the product has no image, show default image
   */
  const productImageUrl = (id: number) => {
    const productImage = _.find(product.product_images_attributes, { id });
    if (productImage) {
      return productImage.attachment_url;
    }
    return noImage;
  };

  /**
   * Returns CSS class from stock status
   */
  const statusColor = (product: Product) => {
    if (product.stock.external < (product.quantity_min || 1)) {
      return 'out-of-stock';
    }
    if (product.low_stock_threshold && product.stock.external < product.low_stock_threshold) {
      return 'low';
    }
  };

  /**
   * Return product's stock status
   */
  const productStockStatus = (product: Product) => {
    if (product.stock.external < (product.quantity_min || 1)) {
      return <span>{t('app.public.store_product_item.out_of_stock')}</span>;
    }
    if (product.low_stock_threshold && product.stock.external < product.low_stock_threshold) {
      return <span>{t('app.public.store_product_item.limited_stock')}</span>;
    }
    return <span>{t('app.public.store_product_item.available')}</span>;
  };

  /**
   * Update product count
   */
  const setCount = (type: 'add' | 'remove') => {
    switch (type) {
      case 'add':
        if (toCartCount < product.stock.external) {
          setToCartCount(toCartCount + 1);
        }
        break;
      case 'remove':
        if (toCartCount > product.quantity_min) {
          setToCartCount(toCartCount - 1);
        }
        break;
    }
  };
  /**
   * Update product count
   */
  const typeCount = (evt: React.ChangeEvent<HTMLInputElement>) => {
    evt.preventDefault();
    setToCartCount(Number(evt.target.value));
  };

  /**
   * Add product to cart
   */
  const addToCart = () => {
    if (toCartCount <= product.stock.external) {
      CartAPI.addItem(cart, product.id, toCartCount).then(data => {
        setCart(data);
        onSuccess(t('app.public.store.add_to_cart_success'));
      }).catch(onError);
    }
  };

  if (product) {
    return (
      <div className={`store-product ${statusColor(product) || ''}`}>
        <span className='ref'>ref: {product.sku}</span>
        <h2 className='name'>{product.name}</h2>
        <div className='gallery'>
          <div className='main'>
            <div className='picture'>
              <img src={productImageUrl(showImage)} alt='' />
            </div>
          </div>
          {product.product_images_attributes.length > 1 &&
            <div className='thumbnails'>
              {product.product_images_attributes.map(i => (
                <div key={i.id} className={`picture ${i.id === showImage ? 'is-active' : ''}`}>
                  <img alt='' onClick={() => setShowImage(i.id)} src={i.attachment_url} />
                </div>
              ))}
            </div>
          }
        </div>
        <div className='description'>
          <div ref={descContainer} dangerouslySetInnerHTML={{ __html: product.description }} className='description-text' style={{ maxHeight: collapseDescription ? '35rem' : '1000rem' }} />
          {displayToggle &&
            <button onClick={() => setCollapseDescription(!collapseDescription)} className='description-toggle'>
              {collapseDescription
                ? <span>{t('app.public.store_product.show_more')}</span>
                : <span>{t('app.public.store_product.show_less')}</span>
              }
            </button>
          }
          {product.product_files_attributes.length > 0 &&
            <div className='description-document'>
              <p>{t('app.public.store_product.documentation')}</p>
              <div className='list'>
                {product.product_files_attributes.map(f =>
                  <a key={f.id} href={f.attachment_url}
                    target='_blank'
                    className='fab-button'
                    rel='noreferrer'>
                    <FilePdf size={24} />
                    <span>{f.attachment_name}</span>
                  </a>
                )}
              </div>
            </div>
          }
        </div>

        <aside>
          <FabStateLabel status={statusColor(product)}>
            {productStockStatus(product)}
          </FabStateLabel>
          <div className='price'>
            <p>{FormatLib.price(product.amount)} <sup>TTC</sup></p>
            <span>/ {t('app.public.store_product_item.unit')}</span>
          </div>
          {product.stock.external > (product.quantity_min || 1) &&
            <div className='to-cart'>
              <FabButton onClick={() => setCount('remove')} icon={<Minus size={16} />} className="minus" />
              <input type="number"
                value={toCartCount}
                min={product.quantity_min}
                max={product.stock.external}
                onChange={evt => typeCount(evt)} />
              <FabButton onClick={() => setCount('add')} icon={<Plus size={16} />} className="plus" />
              <FabButton onClick={() => addToCart()} icon={<i className="fas fa-cart-arrow-down" />}
                className="main-action-btn">
                {t('app.public.store_product_item.add_to_cart')}
              </FabButton>
            </div>
          }
        </aside>
      </div>
    );
  }
  return null;
};

const StoreProductWrapper: React.FC<StoreProductProps> = (props) => {
  return (
    <Loader>
      <StoreProduct {...props} />
    </Loader>
  );
};

Application.Components.component('storeProduct', react2angular(StoreProductWrapper, ['productSlug', 'currentUser', 'onSuccess', 'onError']));
