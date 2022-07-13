import React from 'react';
import { ProductCategory } from '../../models/product-category';
import { DotsSixVertical } from 'phosphor-react';
import { FabButton } from '../base/fab-button';
import { ManageProductCategory } from './manage-product-category';

interface ProductCategoriesListProps {
  productCategories: Array<ProductCategory>,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a Tree list of all Product's Categories
 */
export const ProductCategoriesList: React.FC<ProductCategoriesListProps> = ({ productCategories, onSuccess, onError }) => {
  return (
    <div className='product-categories-list'>
      {productCategories.map((category) => (
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
            <FabButton icon={<DotsSixVertical size={16} />} className='draghandle' />
          </div>
        </div>
      ))}
    </div>
  );
};
