import React from 'react';
import { FabButton } from '../base/fab-button';
import { ProductCategory } from '../../models/product-category';

interface ProductCategoriesListProps {
  productCategories: Array<ProductCategory>,
  onEdit: (category: ProductCategory) => void,
  onDelete: (categoryId: number) => void,
}

/**
 * This component shows a Tree list of all Product's Categories
 */
export const ProductCategoriesList: React.FC<ProductCategoriesListProps> = ({ productCategories, onEdit, onDelete }) => {
  /**
   * Init the process of editing the given product category
   */
  const editProductCategory = (category: ProductCategory): () => void => {
    return (): void => {
      onEdit(category);
    };
  };

  /**
   * Init the process of delete the given product category
   */
  const deleteProductCategory = (categoryId: number): () => void => {
    return (): void => {
      onDelete(categoryId);
    };
  };

  return (
    <div>
      {productCategories.map((category) => (
        <div key={category.id}>
          {category.name}
          <div className="buttons">
            <FabButton className="edit-btn" onClick={editProductCategory(category)}>
              <i className="fa fa-edit" />
            </FabButton>
            <FabButton className="delete-btn" onClick={deleteProductCategory(category.id)}>
              <i className="fa fa-trash" />
            </FabButton>
          </div>
        </div>
      ))}
    </div>
  );
};
