import React, { useEffect, useState } from 'react';
import Select from 'react-select';
import { PencilSimple } from 'phosphor-react';
import { ArrayPath, Path, useFieldArray, UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { Control, FormState, UnpackNestedValue, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { useTranslation } from 'react-i18next';
import { Product, ProductStockMovement, StockMovementReason, StockType } from '../../models/product';
import { HtmlTranslate } from '../base/html-translate';
import { FormSwitch } from '../form/form-switch';
import { FormInput } from '../form/form-input';
import { FabAlert } from '../base/fab-alert';
import { FabButton } from '../base/fab-button';
import { ProductStockModal } from './product-stock-modal';
import { FabStateLabel } from '../base/fab-state-label';
import ProductAPI from '../../api/product';
import FormatLib from '../../lib/format';
import { FieldPathValue } from 'react-hook-form/dist/types/path';
import ProductLib from '../../lib/product';

interface ProductStockFormProps<TFieldValues, TContext extends object> {
  currentFormValues: Product,
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues, TContext>,
  formState: FormState<TFieldValues>,
  setValue: UseFormSetValue<TFieldValues>,
  onSuccess: (product: Product) => void,
  onError: (message: string) => void,
}

const DEFAULT_LOW_STOCK_THRESHOLD = 30;

/**
 * Form tab to manage a product's stock
 */
export const ProductStockForm = <TFieldValues extends FieldValues, TContext extends object> ({ currentFormValues, register, control, formState, setValue, onError }: ProductStockFormProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('admin');

  const [activeThreshold, setActiveThreshold] = useState<boolean>(currentFormValues.low_stock_threshold != null);
  // is the update stock modal open?
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [stockMovements, setStockMovements] = useState<Array<ProductStockMovement>>([]);

  const { fields, append } = useFieldArray({ control, name: 'product_stock_movements_attributes' as ArrayPath<TFieldValues> });

  useEffect(() => {
    if (!currentFormValues?.id) return;

    ProductAPI.stockMovements(currentFormValues.id).then(setStockMovements).catch(onError);
  }, []);

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

  type reasonSelectOption = { value: StockMovementReason, label: string };
  /**
   * Creates sorting options to the react-select format
   */
  const buildReasonsOptions = (): Array<reasonSelectOption> => {
    return (['inward_stock', 'returned', 'cancelled', 'inventory_fix', 'sold', 'missing', 'damaged'] as Array<StockMovementReason>).map(key => {
      return { value: key, label: t(ProductLib.stockMovementReasonTrKey(key)) };
    });
  };

  type typeSelectOption = { value: StockType, label: string };
  /**
   * Creates sorting options to the react-select format
   */
  const buildStocksOptions = (): Array<typeSelectOption> => {
    return [
      { value: 'internal', label: t('app.admin.store.product_stock_form.internal') },
      { value: 'external', label: t('app.admin.store.product_stock_form.external') },
      { value: 'all', label: t('app.admin.store.product_stock_form.all') }
    ];
  };

  /**
   * On events option change
   */
  const eventsOptionsChange = (evt: reasonSelectOption) => {
    console.log('Event option:', evt);
  };
  /**
   * On stocks option change
   */
  const stocksOptionsChange = (evt: typeSelectOption) => {
    console.log('Stocks option:', evt);
  };

  /**
   * Toggle stock threshold
   */
  const toggleStockThreshold = (checked: boolean) => {
    setActiveThreshold(checked);
    setValue(
      'low_stock_threshold' as Path<TFieldValues>,
      (checked ? DEFAULT_LOW_STOCK_THRESHOLD : null) as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
    );
  };

  /**
  * Opens/closes the product stock edition modal
  */
  const toggleModal = (): void => {
    setIsOpen(!isOpen);
  };

  /**
   * Triggered when a new product stock movement was added
   */
  const onNewStockMovement = (movement): void => {
    append({ ...movement });
  };

  /**
   * Return the data of the update of the stock for the current product
   */
  const lastStockUpdate = () => {
    if (stockMovements[0]) {
      return stockMovements[0].date;
    } else {
      return currentFormValues?.created_at || new Date();
    }
  };

  return (
    <section className='product-stock-form'>
      <h4>{t('app.admin.store.product_stock_form.stock_up_to_date')}&nbsp;
        <span>{t('app.admin.store.product_stock_form.date_time', {
          DATE: FormatLib.date(lastStockUpdate()),
          TIME: FormatLib.time((lastStockUpdate()))
        })}</span>
      </h4>
      <div></div>
      <div className="stock-item">
        <p className='title'>{currentFormValues?.name}</p>
        <div className="group">
          <span>{t('app.admin.store.product_stock_form.internal')}</span>
          <p>{currentFormValues?.stock?.internal}</p>
        </div>
        <div className="group">
          <span>{t('app.admin.store.product_stock_form.external')}</span>
          <p>{currentFormValues?.stock?.external}</p>
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
          <FabStateLabel>{t('app.admin.store.product_stock_form.low_stock')}</FabStateLabel>
          <div className="threshold-data-content">
            <FormInput id="low_stock_threshold"
                       type="number"
                       register={register}
                       rules={{ required: activeThreshold, min: 1 }}
                       step={1}
                       formState={formState}
                       nullable
                       label={t('app.admin.store.product_stock_form.threshold_level')} />
            <FormSwitch control={control}
                        id="low_stock_alert"
                        formState={formState}
                        label={t('app.admin.store.product_stock_form.threshold_alert')} />
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
              options={buildReasonsOptions()}
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
        {stockMovements.map(movement => <div className="stock-history" key={movement.id}>
          <div className="stock-item">
            <p className='title'>{currentFormValues.name}</p>
            <p>{FormatLib.date(movement.date)}</p>
            <div className="group">
              <span>{movement.stock_type}</span>
              <p>{movement.quantity}</p>
            </div>
            <div className="group">
              <span>{t('app.admin.store.product_stock_form.event_type')}</span>
              <p>{movement.reason}</p>
            </div>
            <div className="group">
              <span>{t('app.admin.store.product_stock_form.stock_level')}</span>
              <p>{movement.remaining_stock}</p>
            </div>
          </div>
        </div>)}
      </div>
      <ProductStockModal onError={onError}
                         onSuccess={onNewStockMovement}
                         isOpen={isOpen}
                         toggleModal={toggleModal} />
      {fields.map((newMovement, index) => (
        <div key={index}>
          <FormInput id={`product_stock_movements_attributes.${index}.stock_type`} register={register} type="hidden" />
          <FormInput id={`product_stock_movements_attributes.${index}.quantity`} register={register} type="hidden" />
          <FormInput id={`product_stock_movements_attributes.${index}.reason`} register={register} type="hidden" />
        </div>
      ))}
    </section>
  );
};
