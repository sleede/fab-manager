import React from 'react';
import { ProductCategory } from '../../../models/product-category';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { ManageProductCategory } from './manage-product-category';
import { DotsSixVertical } from 'phosphor-react';

interface ProductCategoriesItemProps {
  productCategories: Array<ProductCategory>,
  category: ProductCategory,
  isChild?: boolean,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * Renders a draggable category item
 */
export const ProductCategoriesItem: React.FC<ProductCategoriesItemProps> = ({ productCategories, category, isChild, onSuccess, onError }) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition
  } = useSortable({ id: category.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition
  };

  return (
    <div ref={setNodeRef} style={style} className={`product-categories-item ${isChild ? 'is-child' : ''}`}>
      <div className='itemInfo'>
        <p className='itemInfo-name'>{category.name}</p>
        <span className='itemInfo-count'>[count]</span>
      </div>
      <div className='action'>
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
        <div>
          <button {...attributes} {...listeners} className='draghandle'>
            <DotsSixVertical size={16} />
          </button>
        </div>
      </div>
    </div>
  );
};
