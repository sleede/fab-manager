import React from 'react';
import { ProductIndexFilter } from '../../../models/product';
import { X } from 'phosphor-react';
import { ProductCategory } from '../../../models/product-category';
import { Machine } from '../../../models/machine';
import { useTranslation } from 'react-i18next';

interface ActiveFiltersTagsProps {
  filters: ProductIndexFilter,
  onRemoveCategory: (category: ProductCategory) => void,
  onRemoveMachine: (machine: Machine) => void,
  onRemoveKeyword: () => void,
  onRemoveStock: () => void,
}

/**
 * Some tags listing the currently actives filters for a product list
 */
export const ActiveFiltersTags: React.FC<ActiveFiltersTagsProps> = ({ filters, onRemoveCategory, onRemoveMachine, onRemoveKeyword, onRemoveStock }) => {
  const { t } = useTranslation('shared');
  return (
    <>
      {filters.categories.map(c => (
        <div key={c.id} className='features-item'>
          <p>{c.name}</p>
          <button onClick={() => onRemoveCategory(c)}><X size={16} weight="light" /></button>
        </div>
      ))}
      {filters.machines.map(m => (
        <div key={m.id} className='features-item'>
          <p>{m.name}</p>
          <button onClick={() => onRemoveMachine(m)}><X size={16} weight="light" /></button>
        </div>
      ))}
      {filters.keywords[0] && <div className='features-item'>
        <p>{filters.keywords[0]}</p>
        <button onClick={onRemoveKeyword}><X size={16} weight="light" /></button>
      </div>}
      {(filters.stock_to !== 0 || filters.stock_from !== 0) && <div className='features-item'>
        <p>{t(`app.shared.active_filters_tags.stock_${filters.stock_type}`)} [{filters.stock_from || '…'} ⟶ {filters.stock_to || '…'}]</p>
        <button onClick={onRemoveStock}><X size={16} weight="light" /></button>
      </div>}
    </>
  );
};
