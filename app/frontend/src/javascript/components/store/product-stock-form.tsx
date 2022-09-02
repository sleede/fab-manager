import React from 'react';
import { Product } from '../../models/product';
import { useTranslation } from 'react-i18next';
import { Control } from 'react-hook-form';
import { FormSwitch } from '../form/form-switch';

interface ProductStockFormProps {
  product: Product,
  control: Control,
  onSuccess: (product: Product) => void,
  onError: (message: string) => void,
}

/**
 * Form tab to manage product's stock
 */
export const ProductStockForm: React.FC<ProductStockFormProps> = ({ product, control, onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  /**
   * Toggle stock threshold
   */
  const toggleStockThreshold = (checked: boolean) => {
    console.log('Stock threshold:', checked);
  };

  return (
    <section>
      <h4>Stock à jour <span>00/00/0000 - 00H30</span></h4>
      <div></div>
      <hr />

      <div className="header-switch">
        <h4 className='span-7'>{t('app.admin.store.product_stock_form.low_stock_threshold')}</h4>
        <FormSwitch control={control}
                    id="is_active_threshold"
                    label={t('app.admin.store.product_stock_form.toggle_stock_threshold')}
                    defaultValue={false}
                    onChange={toggleStockThreshold}
                    className='span-3' />
      </div>
    </section>
  );
};
