import React from 'react';
import { FabButton } from '../base/fab-button';
import { Product } from '../../models/product';
import { PencilSimple, Trash } from 'phosphor-react';

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
    <>
      {products.map((product) => (
        <div className='products-list-item' key={product.id}>
          <div className='itemInfo'>
            <img src='https://via.placeholder.com/300' alt='' className='itemInfo-thumbnail' />
            <p className="itemInfo-name">{product.name}</p>
          </div>
          <div className=''></div>
          <div className='actions'>
            <div className='manage'>
              <FabButton className='edit-btn' onClick={editProduct(product)}>
                <PencilSimple size={20} weight="fill" />
              </FabButton>
              <FabButton className='delete-btn' onClick={deleteProduct(product.id)}>
                <Trash size={20} weight="fill" />
              </FabButton>
            </div>
          </div>
        </div>
      ))}
    </>
  );
};
