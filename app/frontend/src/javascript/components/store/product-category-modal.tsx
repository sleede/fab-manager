import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { FabModal } from '../base/fab-modal';
import { ProductCategoryForm } from './product-category-form';
import { ProductCategory } from '../../models/product-category';
import ProductCategoryAPI from '../../api/product-category';

interface ProductCategoryModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
  productCategories: Array<ProductCategory>,
  productCategory?: ProductCategory,
}

/**
 * Check if string is a valid url slug
 */
function checkIfValidURLSlug (str: string): boolean {
  // Regular expression to check if string is a valid url slug
  const regexExp = /^[a-z0-9]+(?:-[a-z0-9]+)*$/g;

  return regexExp.test(str);
}

/**
 * Modal dialog to create/edit a category of product
 */
export const ProductCategoryModal: React.FC<ProductCategoryModalProps> = ({ isOpen, toggleModal, onSuccess, onError, productCategories, productCategory }) => {
  const { t } = useTranslation('admin');

  const [data, setData] = useState<ProductCategory>({
    id: productCategory?.id,
    name: productCategory?.name || '',
    slug: productCategory?.slug || '',
    parent_id: productCategory?.parent_id,
    position: productCategory?.position
  });

  useEffect(() => {
    setData({
      id: productCategory?.id,
      name: productCategory?.name || '',
      slug: productCategory?.slug || '',
      parent_id: productCategory?.parent_id,
      position: productCategory?.position
    });
  }, [productCategory]);

  /**
   * Callback triggered when an inner form field has changed: updates the internal state accordingly
   */
  const handleChanged = (field: string, value: string | number) => {
    setData({
      ...data,
      [field]: value
    });
  };

  /**
   * Save the current product category to the API
   */
  const handleSave = async (): Promise<void> => {
    try {
      if (productCategory?.id) {
        await ProductCategoryAPI.update(data);
        onSuccess(t('app.admin.store.product_category_modal.successfully_updated'));
      } else {
        await ProductCategoryAPI.create(data);
        onSuccess(t('app.admin.store.product_category_modal.successfully_created'));
      }
    } catch (e) {
      if (productCategory?.id) {
        onError(t('app.admin.store.product_category_modal.unable_to_update') + e);
      } else {
        onError(t('app.admin.store.product_category_modal.unable_to_create') + e);
      }
    }
  };

  /**
   * Check if the form is valid (not empty, url valid slug)
   */
  const isPreventedSaveProductCategory = (): boolean => {
    return !data.name || !data.slug || !checkIfValidURLSlug(data.slug);
  };

  return (
    <FabModal title={t(`app.admin.store.product_category_modal.${productCategory ? 'edit' : 'new'}_product_category`)}
      isOpen={isOpen}
      toggleModal={toggleModal}
      closeButton={true}
      confirmButton={t('app.admin.store.product_category_modal.save')}
      onConfirm={handleSave}
      preventConfirm={isPreventedSaveProductCategory()}>
      <ProductCategoryForm productCategory={productCategory} productCategories={productCategories} onChange={handleChanged}/>
    </FabModal>
  );
};
