import { useEffect, useState } from 'react';
import Select from 'react-select';
import { PencilSimple, X } from 'phosphor-react';
import { useFieldArray, UseFormRegister } from 'react-hook-form';
import { Control, FormState, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { useTranslation } from 'react-i18next';
import {
  Product,
  stockMovementAllReasons, StockMovementIndex, StockMovementIndexFilter,
  StockMovementReason,
  StockType
} from '../../models/product';
import { HtmlTranslate } from '../base/html-translate';
import { FormSwitch } from '../form/form-switch';
import { FormInput } from '../form/form-input';
import { FabAlert } from '../base/fab-alert';
import { FabButton } from '../base/fab-button';
import { ProductStockModal } from './product-stock-modal';
import { FabStateLabel } from '../base/fab-state-label';
import ProductAPI from '../../api/product';
import FormatLib from '../../lib/format';
import ProductLib from '../../lib/product';
import { useImmer } from 'use-immer';
import { FabPagination } from '../base/fab-pagination';

interface ProductStockFormProps<TContext extends object> {
  currentFormValues: Product,
  register: UseFormRegister<Product>,
  control: Control<Product, TContext>,
  formState: FormState<Product>,
  setValue: UseFormSetValue<Product>,
  onSuccess: (product: Product) => void,
  onError: (message: string) => void,
}

const DEFAULT_LOW_STOCK_THRESHOLD = 30;

/**
 * Form tab to manage a product's stock
 */
export const ProductStockForm = <TContext extends object> ({ currentFormValues, register, control, formState, setValue, onError }: ProductStockFormProps<TContext>) => {
  const { t } = useTranslation('admin');

  const [activeThreshold, setActiveThreshold] = useState<boolean>(currentFormValues.low_stock_threshold != null);
  // is the update stock modal open?
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [stockMovements, setStockMovements] = useState<StockMovementIndex>(null);
  const [filters, setFilters] = useImmer<StockMovementIndexFilter>({ page: 1 });

  const { fields, append, remove } = useFieldArray({ control, name: 'product_stock_movements_attributes' });

  useEffect(() => {
    if (!currentFormValues?.id) return;

    ProductAPI.stockMovements(currentFormValues.id, filters).then(setStockMovements).catch(onError);
  }, [filters]);

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
    return stockMovementAllReasons.map(key => {
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
   * On stock movement reason filter change
   */
  const eventsOptionsChange = (evt: reasonSelectOption) => {
    setFilters(draft => {
      return {
        ...draft,
        reason: evt.value
      };
    });
  };
  /**
   * On stocks type filter change
   */
  const stocksOptionsChange = (evt: typeSelectOption) => {
    setFilters(draft => {
      return {
        ...draft,
        stock_type: evt.value
      };
    });
  };

  /**
   * Callback triggered when the user wants to swich the current page of stock movements
   */
  const handlePagination = (page: number) => {
    setFilters(draft => {
      return {
        ...draft,
        page
      };
    });
  };

  /**
   * Toggle stock threshold
   */
  const toggleStockThreshold = (checked: boolean) => {
    setActiveThreshold(checked);
    setValue(
      'low_stock_threshold',
      (checked ? DEFAULT_LOW_STOCK_THRESHOLD : null)
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
    if (stockMovements?.data[0]) {
      return stockMovements?.data[0].date;
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

      {fields.length > 0 && <div className="ongoing-stocks">
        <span className="title">{t('app.admin.store.product_stock_form.ongoing_operations')}</span>
        <span className="save-notice">{t('app.admin.store.product_stock_form.save_reminder')}</span>
        {fields.map((newMovement, index) => (
          <div key={index} className="unsaved-stock-movement stock-item">
            <div className="group">
              <p>{t(`app.admin.store.product_stock_form.type_${ProductLib.stockMovementType(newMovement.reason)}`)}</p>
            </div>
            <div className="group">
              <span>{t(`app.admin.store.product_stock_form.${newMovement.stock_type}`)}</span>
              <p>{ProductLib.absoluteStockMovement(newMovement.quantity, newMovement.reason)}</p>
            </div>
            <div className="group">
              <span>{t('app.admin.store.product_stock_form.reason')}</span>
              <p>{t(ProductLib.stockMovementReasonTrKey(newMovement.reason))}</p>
            </div>
            <p className="cancel-action" onClick={() => remove(index)}>
              {t('app.admin.store.product_stock_form.cancel')}
              <X size={20} />
            </p>
            <FormInput id={`product_stock_movements_attributes.${index}.stock_type`} register={register}
                       type="hidden" />
            <FormInput id={`product_stock_movements_attributes.${index}.quantity`} register={register} type="hidden" />
            <FormInput id={`product_stock_movements_attributes.${index}.reason`} register={register} type="hidden" />
          </div>
        ))}
      </div>}

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
        {stockMovements?.data?.map(movement => <div className="stock-history" key={movement.id}>
          <div className="stock-item">
            <p className='title'>{currentFormValues.name}</p>
            <p>{FormatLib.date(movement.date)}</p>
            <div className="group">
              <span>{t(`app.admin.store.product_stock_form.${movement.stock_type}`)}</span>
              <p>{ProductLib.absoluteStockMovement(movement.quantity, movement.reason)}</p>
            </div>
            <div className="group">
              <span>{t('app.admin.store.product_stock_form.reason')}</span>
              <p>{t(ProductLib.stockMovementReasonTrKey(movement.reason))}</p>
            </div>
            <div className="group">
              <span>{t('app.admin.store.product_stock_form.remaining_stock')}</span>
              <p>{movement.remaining_stock}</p>
            </div>
          </div>
        </div>)}
        {stockMovements?.total_pages > 1 &&
          <FabPagination pageCount={stockMovements.total_pages}
                         currentPage={stockMovements.page}
                         selectPage={handlePagination} />
        }
      </div>
      <ProductStockModal onSuccess={onNewStockMovement}
                         isOpen={isOpen}
                         toggleModal={toggleModal} />
    </section>
  );
};
