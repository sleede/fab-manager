import React from 'react';
import { useTranslation } from 'react-i18next';
import _ from 'lodash';
import { FabButton } from '../base/fab-button';
import { Product } from '../../models/product';
import { Order } from '../../models/order';
import FormatLib from '../../lib/format';
import CartAPI from '../../api/cart';
import noImage from '../../../../images/no_image.png';

interface StoreProductItemProps {
  product: Product,
  cart: Order,
  onSuccessAddProductToCart: (cart: Order) => void
}

/**
 * This component shows a product item in store
 */
export const StoreProductItem: React.FC<StoreProductItemProps> = ({ product, cart, onSuccessAddProductToCart }) => {
  const { t } = useTranslation('public');

  /**
   * Return main image of Product, if the product has no image, show default image
   */
  const productImageUrl = (product: Product) => {
    const productImage = _.find(product.product_images_attributes, { is_main: true });
    if (productImage) {
      return productImage.attachment_url;
    }
    return noImage;
  };

  /**
   * Add the product to cart
   */
  const addProductToCart = (e: React.BaseSyntheticEvent) => {
    e.preventDefault();
    e.stopPropagation();
    CartAPI.addItem(cart, product.id, 1).then(onSuccessAddProductToCart);
  };

  /**
   * Goto show product page
   */
  const showProduct = (product: Product): void => {
    window.location.href = `/#!/store/p/${product.slug}`;
  };

  /**
   * Returns CSS class from stock status
   */
  const statusColor = (product: Product) => {
    if (product.stock.external === 0 && product.stock.internal === 0) {
      return 'out-of-stock';
    }
    if (product.low_stock_alert) {
      return 'low';
    }
  };

  /**
   * Return product's stock status
   */
  const productStockStatus = (product: Product) => {
    if (product.stock.external === 0) {
      return <span>{t('app.public.store_product_item.out_of_stock')}</span>;
    }
    if (product.low_stock_threshold && product.stock.external < product.low_stock_threshold) {
      return <span>{t('app.public.store_product_item.limited_stock')}</span>;
    }
    return <span>{t('app.public.store_product_item.available')}</span>;
  };

  return (
    <div className={`store-product-item ${statusColor(product)}`} onClick={() => showProduct(product)}>
      <div className="picture">
        <img src={productImageUrl(product)} alt='' />
      </div>
      <p className="name">{product.name}</p>
      {product.amount &&
        <div className='price'>
          <p>{FormatLib.price(product.amount)}</p>
          <span>/ {t('app.public.store_product_item.unit')}</span>
        </div>
      }
      <div className="stock-label">
        {productStockStatus(product)}
      </div>
      {product.stock.external > 0 &&
        <FabButton icon={<i className="fas fa-cart-arrow-down" />} className="main-action-btn" onClick={addProductToCart}>
          {t('app.public.store_product_item.add')}
        </FabButton>
      }
    </div>
  );
};
