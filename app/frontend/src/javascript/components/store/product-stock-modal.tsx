import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  ProductStockMovement,
  stockMovementInReasons,
  stockMovementOutReasons,
  StockMovementReason,
  StockType
} from '../../models/product';
import { FormSelect } from '../form/form-select';
import { FormInput } from '../form/form-input';
import { FabButton } from '../base/fab-button';
import { FabModal, ModalSize } from '../base/fab-modal';
import { useForm } from 'react-hook-form';
import ProductLib from '../../lib/product';

type reasonSelectOption = { value: StockMovementReason, label: string };
type typeSelectOption = { value: StockType, label: string };

interface ProductStockModalProps {
  onSuccess: (movement: ProductStockMovement) => void,
  onError: (message: string) => void,
  isOpen: boolean,
  toggleModal: () => void,
}

/**
 * Form to manage a product's stock movement and quantity
 */
// TODO: delete next eslint disable
// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const ProductStockModal: React.FC<ProductStockModalProps> = ({ onError, onSuccess, isOpen, toggleModal }) => {
  const { t } = useTranslation('admin');

  const [movement, setMovement] = useState<'in' | 'out'>('in');

  const { handleSubmit, register, control, formState } = useForm<ProductStockMovement>();

  /**
   * Toggle between adding or removing product from stock
   */
  const toggleMovementType = (evt: React.MouseEvent<HTMLButtonElement, MouseEvent>, type: 'in' | 'out') => {
    evt.preventDefault();
    setMovement(type);
  };

  /**
   * Callback triggered when the user validates the new stock movement.
   * We do not use handleSubmit() directly to prevent the propagaion of the "submit" event to the parent form
   */
  const onSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }
    return handleSubmit((data: ProductStockMovement) => {
      onSuccess(data);
      toggleModal();
    })(event);
  };

  /**
   * Creates sorting options to the react-select format
   */
  const buildEventsOptions = (): Array<reasonSelectOption> => {
    return (movement === 'in' ? stockMovementInReasons : stockMovementOutReasons).map(key => {
      return { value: key, label: t(ProductLib.stockMovementReasonTrKey(key)) };
    });
  };
  /**
   * Creates sorting options to the react-select format
   */
  const buildStocksOptions = (): Array<typeSelectOption> => {
    return [
      { value: 'internal', label: t('app.admin.store.product_stock_modal.internal') },
      { value: 'external', label: t('app.admin.store.product_stock_modal.external') }
    ];
  };

  return (
    <FabModal title={t('app.admin.store.product_stock_modal.modal_title')}
              width={ModalSize.large}
              isOpen={isOpen}
              toggleModal={toggleModal}
              className="product-stock-modal"
              closeButton>
      <form onSubmit={onSubmit}>
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
                    id="stock_type"
                    formState={formState}
                    label={t('app.admin.store.product_stock_modal.stocks')} />
        <FormInput id="quantity"
                    type="number"
                    register={register}
                    rules={{ required: true, min: 1 }}
                    step={1}
                    formState={formState}
                    label={t('app.admin.store.product_stock_modal.quantity')} />
        <FormSelect options={buildEventsOptions()}
                    control={control}
                    id="reason"
                    formState={formState}
                    label={t('app.admin.store.product_stock_modal.reason_type')} />
        <FabButton type='submit'>{t('app.admin.store.product_stock_modal.update_stock')} </FabButton>
      </form>
    </FabModal>
  );
};
