import React, { useEffect, useState } from 'react';
import { FabButton } from '../../base/fab-button';
import { AccordionItem } from '../../base/accordion-item';
import { useTranslation } from 'react-i18next';
import { ProductIndexFilter, StockType } from '../../../models/product';
import { FormSelect } from '../../form/form-select';
import { FormInput } from '../../form/form-input';
import { useForm } from 'react-hook-form';
import _ from 'lodash';

interface StockFilterProps {
  onApplyFilters: (filters: ProductIndexFilter) => void,
  currentFilters: ProductIndexFilter,
  openDefault?: boolean
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: StockType, label: string };

/**
 * Component to filter the products list by stock
 */
export const StockFilter: React.FC<StockFilterProps> = ({ onApplyFilters, currentFilters, openDefault = false }) => {
  const { t } = useTranslation('admin');

  const [openedAccordion, setOpenedAccordion] = useState<boolean>(openDefault);

  const { register, control, handleSubmit, getValues, reset } = useForm<ProductIndexFilter>({ defaultValues: { ...currentFilters } });

  useEffect(() => {
    if (currentFilters && !_.isEqual(currentFilters, getValues())) {
      reset(currentFilters);
    }
  }, [currentFilters]);

  /**
   * Open/close the accordion item
   */
  const handleAccordion = (id, state: boolean) => {
    setOpenedAccordion(state);
  };

  /**
   * Callback triggered when the user clicks on "apply" to apply teh current filters.
   */
  const onSubmit = (data: ProductIndexFilter) => {
    onApplyFilters(data);
  };

  /** Creates sorting options to the react-select format */
  const buildStockOptions = (): Array<selectOption> => {
    return [
      { value: 'internal', label: t('app.admin.store.stock_filter.stock_internal') },
      { value: 'external', label: t('app.admin.store.stock_filter.stock_external') }
    ];
  };

  return (
    <>
      <AccordionItem id={3}
                     isOpen={openedAccordion}
                     onChange={handleAccordion}
                     label={t('app.admin.store.stock_filter.filter_stock')}>
        <form className="content" onSubmit={handleSubmit(onSubmit)}>
          <div className="group">
            <FormSelect id="stock_type"
                        options={buildStockOptions()}
                        valueDefault="internal"
                        control={control}
            />
            <div className='range'>
              <FormInput id="stock_from"
                         label={t('app.admin.store.stock_filter.filter_stock_from')}
                         register={register}
                         defaultValue={0}
                         type="number" />
              <FormInput id="stock_to"
                         label={t('app.admin.store.stock_filter.filter_stock_to')}
                         register={register}
                         defaultValue={0}
                         type="number" />
            </div>
            <FabButton type="submit" className="is-info">{t('app.admin.store.stock_filter.filter_apply')}</FabButton>
          </div>
        </form>
      </AccordionItem>
    </>
  );
};
