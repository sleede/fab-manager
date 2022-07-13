import React from 'react';
import { FabButton } from '../base/fab-button';
import { Product } from '../../models/product';

interface ProductsListProps {
  products: Array<Product>,
  onEdit: (product: Product) => void,
  onDelete: (productId: number) => void,
}

/**
 * This component shows a list of all Products
 */
export const ProductsList: React.FC<ProductsListProps> = ({ products, onEdit, onDelete }) => {
  /**
   * Init the process of editing the given product
   */
  const editProduct = (product: Product): () => void => {
    return (): void => {
      onEdit(product);
    };
  };

  /**
   * Init the process of delete the given product
   */
  const deleteProduct = (productId: number): () => void => {
    return (): void => {
      onDelete(productId);
    };
  };

  return (
    <div>
      {products.map((product) => (
        <div key={product.id}>
          {product.name}
          <div className="buttons">
            <FabButton className="edit-btn" onClick={editProduct(product)}>
              <i className="fa fa-edit" />
            </FabButton>
            <FabButton className="delete-btn" onClick={deleteProduct(product.id)}>
              <i className="fa fa-trash" />
            </FabButton>
          </div>
        </div>
      ))}
    </div>
  );
};
