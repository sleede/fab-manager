import React, { useState } from 'react';
import { Product } from '../../models/product';
import { UseFormRegister } from 'react-hook-form';
import { Control, FormState } from 'react-hook-form/dist/types/form';
import { useTranslation } from 'react-i18next';
import { HtmlTranslate } from '../base/html-translate';
import { FormSwitch } from '../form/form-switch';
import { FormInput } from '../form/form-input';
import Select from 'react-select';
import { FabAlert } from '../base/fab-alert';
import { FabButton } from '../base/fab-button';
import { PencilSimple } from 'phosphor-react';
import { FabModal, ModalSize } from '../base/fab-modal';
import { ProductStockModal } from './product-stock-modal';

interface ProductStockFormProps<TFieldValues, TContext extends object> {
  product: Product,
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues, TContext>,
  formState: FormState<TFieldValues>,
  onSuccess: (product: Product) => void,
  onError: (message: string) => void,
}

/**
 * Form tab to manage a product's stock
 */
export const ProductStockForm = <TFieldValues, TContext extends object> ({ product, register, control, formState, onError, onSuccess }: ProductStockFormProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('admin');

  const [activeThreshold, setActiveThreshold] = useState<boolean>(false);
  // is the modal open?
  const [isOpen, setIsOpen] = useState<boolean>(false);

  // Styles the React-select component
  const customStyles = {
    control: base => ({
      ...base,
      width: '20ch',
      border: 'none',
      backgroundColor: 'transparent'
    }),
    indicatorSeparator: () => ({
      display: 'none'
    })
  };

  type selectOption = { value: number, label: string };
  /**
   * Creates sorting options to the react-select format
   */
  const buildEventsOptions = (): Array<selectOption> => {
    return [
      { value: 0, label: t('app.admin.store.product_stock_form.events.inward_stock') },
      { value: 1, label: t('app.admin.store.product_stock_form.events.returned') },
      { value: 2, label: t('app.admin.store.product_stock_form.events.canceled') },
      { value: 3, label: t('app.admin.store.product_stock_form.events.sold') },
      { value: 4, label: t('app.admin.store.product_stock_form.events.missing') },
      { value: 5, label: t('app.admin.store.product_stock_form.events.damaged') }
    ];
  };
  /**
   * Creates sorting options to the react-select format
   */
  const buildStocksOptions = (): Array<selectOption> => {
    return [
      { value: 0, label: t('app.admin.store.product_stock_form.internal') },
      { value: 1, label: t('app.admin.store.product_stock_form.external') },
      { value: 2, label: t('app.admin.store.product_stock_form.all') }
    ];
  };

  /**
   * On events option change
   */
  const eventsOptionsChange = (evt: selectOption) => {
    console.log('Event option:', evt);
  };
  /**
   * On stocks option change
   */
  const stocksOptionsChange = (evt: selectOption) => {
    console.log('Stocks option:', evt);
  };

  /**
   * Toggle stock threshold
   */
  const toggleStockThreshold = (checked: boolean) => {
    setActiveThreshold(checked);
  };

  /**
  * Opens/closes the product category modal
  */
  const toggleModal = (): void => {
    setIsOpen(!isOpen);
  };

  /**
   * Toggle stock threshold alert
   */
  const toggleStockThresholdAlert = (checked: boolean) => {
    console.log('Low stock notification:', checked);
  };

  return (
    <section className='product-stock-form'>
      <h4>Stock à jour <span>00/00/0000 - 00H30</span></h4>
      <div></div>
      <div className="stock-item">
        <p className='title'>Product name</p>
        <div className="group">
          <span>{t('app.admin.store.product_stock_form.internal')}</span>
          <p>00</p>
        </div>
        <div className="group">
          <span>{t('app.admin.store.product_stock_form.external')}</span>
          <p>000</p>
        </div>
        <FabButton onClick={toggleModal} icon={<PencilSimple size={20} weight="fill" />} className="is-black">Modifier</FabButton>
      </div>
      <hr />

      <div className="threshold-data">
        <div className="header-switch">
          <h4>{t('app.admin.store.product_stock_form.low_stock_threshold')}</h4>
          <FormSwitch control={control}
                      id="is_active_threshold"
                      label={t('app.admin.store.product_stock_form.stock_threshold_toggle')}
                      defaultValue={activeThreshold}
                      onChange={toggleStockThreshold} />
        </div>
        <FabAlert level="warning">
          <HtmlTranslate trKey="app.admin.store.product_stock_form.stock_threshold_information" />
        </FabAlert>
        {activeThreshold && <>
          <span className='stock-label'>{t('app.admin.store.product_stock_form.low_stock')}</span>
          <div className="threshold-data-content">
          <FormInput id="threshold"
                     type="number"
                     register={register}
                     rules={{ required: true, min: 1 }}
                     step={1}
                     formState={formState}
                     label={t('app.admin.store.product_stock_form.threshold_level')} />
          <FormSwitch control={control}
                      id="threshold_alert"
                      formState={formState}
                      label={t('app.admin.store.product_stock_form.threshold_alert')}
                      defaultValue={activeThreshold}
                      onChange={toggleStockThresholdAlert} />
          </div>
        </>}
      </div>
      <hr />

      <div className="store-list">
        <h4>{t('app.admin.store.product_stock_form.events_history')}</h4>
        <div className="store-list-header">
          <div className='sort-events'>
            <p>{t('app.admin.store.product_stock_form.event_type')}</p>
            <Select
              options={buildEventsOptions()}
              onChange={evt => eventsOptionsChange(evt)}
              styles={customStyles}
            />
          </div>
          <div className='sort-stocks'>
            <p>{t('app.admin.store.product_stock_form.stocks')}</p>
            <Select
              options={buildStocksOptions()}
              onChange={evt => stocksOptionsChange(evt)}
              styles={customStyles}
            />
          </div>
        </div>
        <div className="stock-history">
          <div className="stock-item">
            <p className='title'>Product name</p>
            <p>00/00/0000</p>
            <div className="group">
              <span>[stock type]</span>
              <p>00</p>
            </div>
            <div className="group">
              <span>{t('app.admin.store.product_stock_form.event_type')}</span>
              <p>[event type]</p>
            </div>
            <div className="group">
              <span>{t('app.admin.store.product_stock_form.stock_level')}</span>
              <p>000</p>
            </div>
          </div>
        </div>
      </div>

      <FabModal title={t('app.admin.store.product_stock_form.modal_title')}
        className="fab-modal-lg"
        width={ModalSize.large}
        isOpen={isOpen}
        toggleModal={toggleModal}
        closeButton>
          <ProductStockModal product={product} register={register} control={control} id="stock-modal" onError={onError} onSuccess={onSuccess} />
      </FabModal>
    </section>
  );
};
