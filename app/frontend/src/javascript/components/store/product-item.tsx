import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { Product } from '../../models/product';
import noImage from '../../../../images/no_image.png';
import { FabStateLabel } from '../base/fab-state-label';
import { ProductPrice } from './product-price';
import { EditDestroyButtons } from '../base/edit-destroy-buttons';
import ProductAPI from '../../api/product';

interface ProductItemProps {
  product: Product,
  onEdit: (product: Product) => void,
  onDelete: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a product item in the admin view
 */
export const ProductItem: React.FC<ProductItemProps> = ({ product, onEdit, onDelete, onError }) => {
  const { t } = useTranslation('admin');

  /**
   * Get the main image
   */
  const thumbnail = () => {
    return product.product_images_attributes.find(att => att.is_main);
  };
  /**
   * Init the process of editing the given product
   */
  const editProduct = (product: Product): () => void => {
    return (): void => {
      onEdit(product);
    };
  };

  /**
   * Returns CSS class from stock status
   */
  const stockColor = (product: Product, stockType: string) => {
    if (product.stock[stockType] < (product.quantity_min || 1)) {
      return 'out-of-stock';
    }
    if (product.low_stock_threshold && product.stock[stockType] <= product.low_stock_threshold) {
      return 'low';
    }
    return '';
  };

  return (
    <div className='product-item'>
      <div className='itemInfo'>
        <img src={thumbnail()?.thumb_attachment_url || noImage} alt='' className='itemInfo-thumbnail' />
        <p className="itemInfo-name">{product.name}</p>
      </div>
      <div className='details'>
        <FabStateLabel status={product.is_active ? 'is-active' : ''} background>
          {product.is_active
            ? t('app.admin.store.product_item.visible')
            : t('app.admin.store.product_item.hidden')
          }
        </FabStateLabel>
        <div className={`stock ${stockColor(product, 'internal')}`}>
          <span>{t('app.admin.store.product_item.stock.internal')}</span>
          <p>{product.stock.internal}</p>
        </div>
        <div className={`stock ${stockColor(product, 'external')}`}>
          <span>{t('app.admin.store.product_item.stock.external')}</span>
          <p>{product.stock.external}</p>
        </div>
        <ProductPrice product={product} className="price" />
      </div>
      <div className='actions'>
        <EditDestroyButtons onDeleteSuccess={onDelete}
                            className="manage"
                            onError={onError}
                            onEdit={editProduct(product)}
                            itemId={product.id}
                            itemType={t('app.admin.store.product_item.product')}
                            destroy={ProductAPI.destroy} />
      </div>
    </div>
  );
};
