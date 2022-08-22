import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import _ from 'lodash';
import { Product } from '../../models/product';
import ProductAPI from '../../api/product';

declare const Application: IApplication;

interface StoreProductProps {
  productSlug: string,
  onError: (message: string) => void,
}

/**
 * This component shows a product
 */
export const StoreProduct: React.FC<StoreProductProps> = ({ productSlug, onError }) => {
  const { t } = useTranslation('public');

  const [product, setProduct] = useState<Product>();

  useEffect(() => {
    ProductAPI.get(productSlug).then(data => {
      setProduct(data);
    }).catch(() => {
      onError(t('app.public.store_product.unexpected_error_occurred'));
    });
  }, []);

  /**
   * Return main image of Product, if the product has not any image, show default image
   */
  const productImageUrl = (product: Product) => {
    const productImage = _.find(product.product_images_attributes, { is_main: true });
    if (productImage) {
      return productImage.attachment_url;
    }
    return 'https://via.placeholder.com/300';
  };

  if (product) {
    return (
      <div className="store-product">
        <img src={productImageUrl(product)} alt='' className='itemInfo-thumbnail' />
        <p className="itemInfo-name">{product.name}</p>
        <div dangerouslySetInnerHTML={{ __html: product.description }} />
      </div>
    );
  }
  return null;
};

const StoreProductWrapper: React.FC<StoreProductProps> = ({ productSlug, onError }) => {
  return (
    <Loader>
      <StoreProduct productSlug={productSlug} onError={onError} />
    </Loader>
  );
};

Application.Components.component('storeProduct', react2angular(StoreProductWrapper, ['productSlug', 'onError']));
