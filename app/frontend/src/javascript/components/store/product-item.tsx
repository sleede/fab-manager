import React from 'react';
import { useTranslation } from 'react-i18next';
import FormatLib from '../../lib/format';
import { FabButton } from '../base/fab-button';
import { Product } from '../../models/product';
import { PencilSimple, Trash } from 'phosphor-react';
import noImage from '../../../../images/no_image.png';
import { FabStateLabel } from '../base/fab-state-label';

interface ProductItemProps {
  product: Product,
  onEdit: (product: Product) => void,
  onDelete: (productId: number) => void,
}

/**
 * This component shows a product item in the admin view
 */
export const ProductItem: React.FC<ProductItemProps> = ({ product, onEdit, onDelete }) => {
  const { t } = useTranslation('admin');

  /**
   * Get the main image
   */
  const thumbnail = () => {
    const image = product.product_images_attributes
      .find(att => att.is_main);
    return image;
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
   * Init the process of delete the given product
   */
  const deleteProduct = (productId: number): () => void => {
    return (): void => {
      onDelete(productId);
    };
  };

  /**
   * Returns CSS class from stock status
   */
  const statusColor = (product: Product) => {
    if (product.stock.external === 0 && product.stock.internal === 0) {
      return 'out-of-stock';
    }
    if (product.low_stock_threshold && (product.stock.external < product.low_stock_threshold || product.stock.internal < product.low_stock_threshold)) {
      return 'low';
    }
  };

  return (
    <div className={`product-item ${statusColor(product)}`}>
      <div className='itemInfo'>
        {/* TODO: image size version ? */}
        <img src={thumbnail()?.attachment_url || noImage} alt='' className='itemInfo-thumbnail' />
        <p className="itemInfo-name">{product.name}</p>
      </div>
      <div className='details'>
        <FabStateLabel status={product.is_active ? 'is-active' : ''} background>
          {product.is_active
            ? t('app.admin.store.product_item.visible')
            : t('app.admin.store.product_item.hidden')
          }
        </FabStateLabel>
        <div className={`stock ${product.stock.internal < product.low_stock_threshold ? 'low' : ''}`}>
          <span>{t('app.admin.store.product_item.stock.internal')}</span>
          <p>{product.stock.internal}</p>
        </div>
        <div className={`stock ${product.stock.external < product.low_stock_threshold ? 'low' : ''}`}>
          <span>{t('app.admin.store.product_item.stock.external')}</span>
          <p>{product.stock.external}</p>
        </div>
        {product.amount &&
          <div className='price'>
            <p>{FormatLib.price(product.amount)}</p>
            <span>/ {t('app.admin.store.product_item.unit')}</span>
          </div>
        }
      </div>
      <div className='actions'>
        <div className='manage'>
          <FabButton className='edit-btn' onClick={editProduct(product)}>
            <PencilSimple size={20} weight="fill" />
          </FabButton>
          <FabButton className='delete-btn' onClick={deleteProduct(product.id)}>
            <Trash size={20} weight="fill" />
          </FabButton>
        </div>
      </div>
    </div>
  );
};
