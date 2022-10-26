import React from 'react';
import { SubmitHandler, useForm } from 'react-hook-form';
import { FormInput } from '../form/form-input';
import { FormSwitch } from '../form/form-switch';
import { useTranslation } from 'react-i18next';
import { FabModal, ModalSize } from '../base/fab-modal';
import { Product } from '../../models/product';
import ProductAPI from '../../api/product';

interface CloneProductModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  onSuccess: (product: Product) => void,
  onError: (message: string) => void,
  product: Product,
}

/**
 * Modal dialog to clone a product
 */
export const CloneProductModal: React.FC<CloneProductModalProps> = ({ isOpen, toggleModal, onSuccess, onError, product }) => {
  const { t } = useTranslation('admin');
  const { handleSubmit, register, control, formState, reset } = useForm<Product>({
    defaultValues: {
      name: product.name,
      sku: product.sku,
      is_active: false
    }
  });

  /**
   * Call product clone api
   */
  const handleClone: SubmitHandler<Product> = (data: Product) => {
    ProductAPI.clone(product, data).then((res) => {
      reset(res);
      onSuccess(res);
    }).catch(onError);
  };

  return (
    <FabModal title={t('app.admin.store.clone_product_modal.clone_product')}
      closeButton
      isOpen={isOpen}
      toggleModal={toggleModal}
      width={ModalSize.medium}
      confirmButton={t('app.admin.store.clone_product_modal.clone')}
      onConfirm={handleSubmit(handleClone)}>
      <form className="clone-product-form" onSubmit={handleSubmit(handleClone)}>
        <FormInput id="name"
                  register={register}
                  rules={{ required: true }}
                  formState={formState}
                  label={t('app.admin.store.clone_product_modal.name')}
                  className="span-12" />
        <FormInput id="sku"
                  register={register}
                  formState={formState}
                  label={t('app.admin.store.clone_product_modal.sku')}
                  className="span-12" />
        {product.is_active &&
          <FormSwitch control={control}
                      id="is_active"
                      formState={formState}
                      label={t('app.admin.store.clone_product_modal.is_show_in_store')}
                      tooltip={t('app.admin.store.clone_product_modal.active_price_info')}
                      className='span-12' />
        }
    </form>
    </FabModal>
  );
};
