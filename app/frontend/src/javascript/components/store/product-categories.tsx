import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { HtmlTranslate } from '../base/html-translate';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { FabAlert } from '../base/fab-alert';
import { FabButton } from '../base/fab-button';
import { ProductCategoriesList } from './product-categories-list';
import { ProductCategoryModal } from './product-category-modal';
import { ProductCategory } from '../../models/product-category';
import ProductCategoryAPI from '../../api/product-category';

declare const Application: IApplication;

interface ProductCategoriesProps {
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a Tree list of all Product's Categories
 */
const ProductCategories: React.FC<ProductCategoriesProps> = ({ onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const [isOpenProductCategoryModal, setIsOpenProductCategoryModal] = useState<boolean>(false);
  const [productCategories, setProductCategories] = useState<Array<ProductCategory>>([]);
  const [productCategory, setProductCategory] = useState<ProductCategory>(null);

  useEffect(() => {
    ProductCategoryAPI.index().then(data => {
      setProductCategories(data);
    });
  }, []);

  /**
   * Open create new product category modal
   */
  const openProductCategoryModal = () => {
    setIsOpenProductCategoryModal(true);
  };

  /**
   * toggle create/edit product category modal
   */
  const toggleCreateAndEditProductCategoryModal = () => {
    setIsOpenProductCategoryModal(!isOpenProductCategoryModal);
  };

  /**
   * callback handle save product category success
   */
  const onSaveProductCategorySuccess = (message: string) => {
    setIsOpenProductCategoryModal(false);
    onSuccess(message);
    ProductCategoryAPI.index().then(data => {
      setProductCategories(data);
    });
  };

  /**
   * Open edit the product category modal
   */
  const editProductCategory = (category: ProductCategory) => {
    setProductCategory(category);
    setIsOpenProductCategoryModal(true);
  };

  /**
   * Delete a product category
   */
  const deleteProductCategory = async (categoryId: number): Promise<void> => {
    try {
      await ProductCategoryAPI.destroy(categoryId);
      const data = await ProductCategoryAPI.index();
      setProductCategories(data);
      onSuccess(t('app.admin.store.product_categories.successfully_deleted'));
    } catch (e) {
      onError(t('app.admin.store.product_categories.unable_to_delete') + e);
    }
  };

  return (
    <div>
      <h2>{t('app.admin.store.product_categories.the_categories')}</h2>
      <FabButton className="save" onClick={openProductCategoryModal}>{t('app.admin.store.product_categories.create_a_product_category')}</FabButton>
      <ProductCategoryModal isOpen={isOpenProductCategoryModal}
                            productCategories={productCategories}
                            productCategory={productCategory}
                            toggleModal={toggleCreateAndEditProductCategoryModal}
                            onSuccess={onSaveProductCategorySuccess}
                            onError={onError} />
      <FabAlert level="warning">
        <HtmlTranslate trKey="app.admin.store.product_categories.info" />
      </FabAlert>
      <ProductCategoriesList
        productCategories={productCategories}
        onEdit={editProductCategory}
        onDelete={deleteProductCategory}
      />
    </div>
  );
};

const ProductCategoriesWrapper: React.FC<ProductCategoriesProps> = ({ onSuccess, onError }) => {
  return (
    <Loader>
      <ProductCategories onSuccess={onSuccess} onError={onError} />
    </Loader>
  );
};

Application.Components.component('productCategories', react2angular(ProductCategoriesWrapper, ['onSuccess', 'onError']));
