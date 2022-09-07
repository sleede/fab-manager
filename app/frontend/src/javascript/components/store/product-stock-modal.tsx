import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Product } from '../../models/product';
import { UseFormRegister } from 'react-hook-form';
import { Control, FormState } from 'react-hook-form/dist/types/form';
import { FormSelect } from '../form/form-select';
import { FormInput } from '../form/form-input';
import { FabButton } from '../base/fab-button';

type selectOption = { value: number, label: string };

interface ProductStockModalProps<TFieldValues, TContext extends object> {
  product: Product,
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues, TContext>,
  formState: FormState<TFieldValues>,
  onSuccess: (product: Product) => void,
  onError: (message: string) => void
}

/**
 * Form to manage a product's stock movement and quantity
 */
// TODO: delete next eslint disable
// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const ProductStockModal = <TFieldValues, TContext extends object> ({ product, register, control, formState, onError, onSuccess }: ProductStockModalProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('admin');

  const [movement, setMovement] = useState<'in' | 'out'>('in');

  /**
   * Toggle between adding or removing product from stock
   */
  const toggleMovementType = (evt: React.MouseEvent<HTMLButtonElement, MouseEvent>, type: 'in' | 'out') => {
    evt.preventDefault();
    setMovement(type);
  };

  /**
   * Creates sorting options to the react-select format
   */
  const buildEventsOptions = (): Array<selectOption> => {
    let options = [];
    movement === 'in'
      ? options = [
        { value: 0, label: t('app.admin.store.product_stock_modal.events.inward_stock') },
        { value: 1, label: t('app.admin.store.product_stock_modal.events.returned') },
        { value: 2, label: t('app.admin.store.product_stock_modal.events.canceled') }
      ]
      : options = [
        { value: 0, label: t('app.admin.store.product_stock_modal.events.sold') },
        { value: 1, label: t('app.admin.store.product_stock_modal.events.missing') },
        { value: 2, label: t('app.admin.store.product_stock_modal.events.damaged') }
      ];
    return options;
  };
  /**
   * Creates sorting options to the react-select format
   */
  const buildStocksOptions = (): Array<selectOption> => {
    return [
      { value: 0, label: t('app.admin.store.product_stock_modal.internal') },
      { value: 1, label: t('app.admin.store.product_stock_modal.external') }
    ];
  };

  return (
    <form className='product-stock-modal'>
      <p className='subtitle'>{t('app.admin.store.product_stock_modal.new_event')}</p>
      <div className="movement">
        <button onClick={(evt) => toggleMovementType(evt, 'in')} className={movement === 'in' ? 'is-active' : ''}>
          {t('app.admin.store.product_stock_modal.addition')}
        </button>
        <button onClick={(evt) => toggleMovementType(evt, 'out')} className={movement === 'out' ? 'is-active' : ''}>
          {t('app.admin.store.product_stock_modal.withdrawal')}
        </button>
      </div>
      <FormSelect options={buildStocksOptions()}
                  control={control}
                  id="updated_stock_type"
                  formState={formState}
                  label={t('app.admin.store.product_stock_modal.stocks')} />
      <FormInput id="updated_stock_quantity"
                  type="number"
                  register={register}
                  rules={{ required: true, min: 1 }}
                  step={1}
                  formState={formState}
                  label={t('app.admin.store.product_stock_modal.quantity')} />
      <FormSelect options={buildEventsOptions()}
                  control={control}
                  id="updated_stock_event"
                  formState={formState}
                  label={t('app.admin.store.product_stock_modal.event_type')} />
      <FabButton type='submit'>{t('app.admin.store.product_stock_modal.update_stock')} </FabButton>
    </form>
  );
};
