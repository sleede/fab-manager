import React from 'react';
import { ProductCategory } from '../../../models/product-category';
import { ManageProductCategory } from './manage-product-category';
import { FabButton } from '../../base/fab-button';
import { DotsSixVertical } from 'phosphor-react';

interface ProductCategoriesItemProps {
  productCategories: Array<ProductCategory>,
  category: ProductCategory,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * Renders a draggable category item
 */
export const ProductCategoriesItem: React.FC<ProductCategoriesItemProps> = ({ productCategories, category, onSuccess, onError }) => {
  return (
    <div key={category.id} className='product-categories-item'>
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
          <FabButton icon={<DotsSixVertical size={16} />} className='draghandle' />
        </div>
      </div>
    </div>
  );
};
