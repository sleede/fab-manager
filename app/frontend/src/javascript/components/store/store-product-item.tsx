import * as React from 'react';
import { useTranslation } from 'react-i18next';
import _ from 'lodash';
import { FabButton } from '../base/fab-button';
import { Product } from '../../models/product';
import { Order } from '../../models/order';
import { FabStateLabel } from '../base/fab-state-label';
import CartAPI from '../../api/cart';
import noImage from '../../../../images/no_image.png';
import { ProductPrice } from './product-price';
import ProductLib from '../../lib/product';

interface StoreProductItemProps {
  product: Product,
  cart: Order,
  onSuccessAddProductToCart: (cart: Order) => void,
  onError: (message: string) => void
}

/**
 * This component shows a product item "card" in the public store list
 */
export const StoreProductItem: React.FC<StoreProductItemProps> = ({ product, cart, onSuccessAddProductToCart, onError }) => {
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
    CartAPI.addItem(cart, product.id, 'Product', 1).then(onSuccessAddProductToCart).catch(() => {
      onError(t('app.public.store_product_item.stock_limit'));
    });
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
    if (product.stock.external < (product.quantity_min || 1)) {
      return 'out-of-stock';
    }
    if (product.low_stock_threshold && product.stock.external <= product.low_stock_threshold) {
      return 'low';
    }
    return '';
  };

  return (
    <div className={`store-product-item ${statusColor(product)}`} onClick={() => showProduct(product)}>
      <div className="picture">
        <img src={productImageUrl(product)} alt='' />
      </div>
      <p className="name">{product.name}</p>
      {product.quantity_min > 1 &&
        <span className='min'>{t('app.public.store_product_item.minimum_purchase')}{product.quantity_min}</span>
      }
      <ProductPrice product={product} className="price" />
      <FabStateLabel status={statusColor(product)}>
        <span>{t(ProductLib.stockStatusTrKey(product))}</span>
      </FabStateLabel>
      {product.stock.external >= (product.quantity_min || 1) &&
        <FabButton icon={<i className="fas fa-cart-arrow-down" />} className="main-action-btn" onClick={addProductToCart}>
          {t('app.public.store_product_item.add')}
        </FabButton>
      }
    </div>
  );
};
