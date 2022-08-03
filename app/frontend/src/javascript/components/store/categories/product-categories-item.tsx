// TODO: Remove next eslint-disable
/* eslint-disable @typescript-eslint/no-unused-vars */
import React from 'react';
import { ProductCategory } from '../../../models/product-category';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { ManageProductCategory } from './manage-product-category';
import { CaretDown, DotsSixVertical } from 'phosphor-react';

interface ProductCategoriesItemProps {
  productCategories: Array<ProductCategory>,
  category: ProductCategory,
  offset: boolean,
  collapsed?: boolean,
  handleCollapse?: (id: number) => void,
  status: 'child' | 'single' | 'parent',
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * Renders a draggable category item
 */
export const ProductCategoriesItem: React.FC<ProductCategoriesItemProps> = ({ productCategories, category, offset, collapsed, handleCollapse, status, onSuccess, onError }) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging
  } = useSortable({ id: category.id });

  const style = {
    transition,
    transform: CSS.Transform.toString(transform)
  };

  return (
    <div ref={setNodeRef} style={style}
      className={`product-categories-item ${(status === 'child' && collapsed) ? 'is-collapsed' : ''}`}>
      {(status === 'child' || offset) &&
        <div className='offset'></div>
      }
      <div className="wrap">
        <div className='itemInfo'>
          {status === 'parent' && <div className='collapse-handle'>
            <button className={collapsed ? '' : 'rotate'} onClick={() => handleCollapse(category.id)}>
              <CaretDown size={16} weight="bold" />
            </button>
          </div>}
          <p className='itemInfo-name'>{category.name}</p>
          <span className='itemInfo-count'>[count]</span>
        </div>
        <div className='actions'>
          <div className='manage'>
            <ManageProductCategory action='update'
              productCategories={productCategories}
              productCategory={category}
              onSuccess={onSuccess} onError={onError} />
            <ManageProductCategory action='delete'
              productCategories={productCategories}
              productCategory={category}
              onSuccess={onSuccess} onError={onError} />
          </div>
          <div className='drag-handle'>
            <button {...attributes} {...listeners}>
              <DotsSixVertical size={20} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
