import React from 'react';
import { useTranslation } from 'react-i18next';
import FormatLib from '../../lib/format';
import { FabButton } from '../base/fab-button';
import { Product } from '../../models/product';
import { PencilSimple, Trash } from 'phosphor-react';
import noImage from '../../../../images/no_image.png';

interface ProductsListProps {
  products: Array<Product>,
  onEdit: (product: Product) => void,
  onDelete: (productId: number) => void,
}

/**
 * This component shows a list of all Products
 */
export const ProductsList: React.FC<ProductsListProps> = ({ products, onEdit, onDelete }) => {
  const { t } = useTranslation('admin');

  /**
   * TODO, document this method
   */
  const thumbnail = (id: number) => {
    const image = products
      ?.find(p => p.id === id)
      .product_images_attributes
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
    if (product.low_stock_alert) {
      return 'low';
    }
  };

  return (
    <>
      {products.map((product) => (
        <div className={`products-list-item ${statusColor(product)}`} key={product.id}>
          <div className='itemInfo'>
            {/* TODO: image size version ? */}
            <img src={thumbnail(product.id)?.attachment_url || noImage} alt='' className='itemInfo-thumbnail' />
            <p className="itemInfo-name">{product.name}</p>
          </div>
          <div className='details'>
            <span className={`visibility ${product.is_active ? 'is-active' : ''}`}>
              {product.is_active
                ? t('app.admin.store.products_list.visible')
                : t('app.admin.store.products_list.hidden')
              }
            </span>
            <div className='stock'>
              <span>{t('app.admin.store.products_list.stock.internal')}</span>
              <p>{product.stock.internal}</p>
            </div>
            <div className='stock'>
              <span>{t('app.admin.store.products_list.stock.external')}</span>
              <p>{product.stock.external}</p>
            </div>
            {product.amount &&
              <div className='price'>
                <p>{FormatLib.price(product.amount)}</p>
                <span>/ {t('app.admin.store.products_list.unit')}</span>
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
      ))}
    </>
  );
};
