import React from 'react';
import { Product } from '../../models/product';
import FormatLib from '../../lib/format';
import { useTranslation } from 'react-i18next';

interface ProductPriceProps {
  product: Product;
  className?: string;
}

/**
 * Render the formatted price for the given product, or "free" if the price is 0 or not set
 */
export const ProductPrice: React.FC<ProductPriceProps> = ({ product, className }) => {
  const { t } = useTranslation('public');

  /**
   * Return the formatted price data
   */
  const renderPrice = (product: Product) => {
    if (product.amount === 0) {
      return <p>{t('app.public.product_price.free')}</p>;
    }
    if ([null, undefined].includes(product.amount)) {
      return <div/>;
    }
    return <>
      <p>{FormatLib.price(product.amount)}</p>
      <span>{t('app.public.product_price.per_unit')}</span>
    </>;
  };

  return (
    <div className={`product-price ${className || ''}`}>
      {renderPrice(product)}
    </div>
  );
};
