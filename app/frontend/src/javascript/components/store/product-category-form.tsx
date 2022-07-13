import React, { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useForm, SubmitHandler } from 'react-hook-form';
import slugify from 'slugify';
import { FormInput } from '../form/form-input';
import { FormSelect } from '../form/form-select';
import { ProductCategory } from '../../models/product-category';
import { FabButton } from '../base/fab-button';
import { FabAlert } from '../base/fab-alert';
import ProductCategoryAPI from '../../api/product-category';

interface ProductCategoryFormProps {
  action: 'create' | 'update' | 'delete',
  productCategories: Array<ProductCategory>,
  productCategory?: ProductCategory,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
 type selectOption = { value: number, label: string };

/**
 * Form to create/edit/delete a product category
 */
export const ProductCategoryForm: React.FC<ProductCategoryFormProps> = ({ action, productCategories, productCategory, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const { register, watch, setValue, control, handleSubmit } = useForm<ProductCategory>({ defaultValues: { ...productCategory } });

  // filter all first level product categorie
  const parents = productCategories.filter(c => !c.parent_id);

  /**
   * Convert all parents to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return parents.map(t => {
      return { value: t.id, label: t.name };
    });
  };

  // Create slug from category's name
  useEffect(() => {
    const subscription = watch((value, { name }) => {
      if (name === 'name') {
        const _slug = slugify(value.name, { lower: true });
        setValue('slug', _slug);
      }
    });
    return () => subscription.unsubscribe();
  }, [watch]);

  // Form submit
  const onSubmit: SubmitHandler<ProductCategory> = (category: ProductCategory) => {
    switch (action) {
      case 'create':
        console.log('create:', category);
        break;
      case 'update':
        console.log('update:', category);
        break;
      case 'delete':
        ProductCategoryAPI.destroy(category.id).then(() => {
          onSuccess(t('app.admin.store.product_category_form.delete.success'));
        }).catch((error) => {
          onError(t('app.admin.store.product_category_form.delete.error') + error);
        });
        break;
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} name="productCategoryForm" className="product-category-form">
      { action === 'delete'
        ? <>
            <FabAlert level='danger'>
              {t('app.admin.store.product_category_form.delete.confirm')}
            </FabAlert>
            <FabButton type='submit'>{t('app.admin.store.product_category_form.save')}</FabButton>
          </>
        : <>
            <FormInput id='name'
                  register={register}
                  rules={{ required: 'true' }}
                  label={t('app.admin.store.product_category_form.name')}
                  defaultValue={productCategory?.name || ''} />
            <FormInput id='slug'
                      register={register}
                      rules={{ required: 'true' }}
                      label={t('app.admin.store.product_category_form.slug')}
                      defaultValue={productCategory?.slug} />
            <FormSelect id='parent_id'
                    control={control}
                    options={buildOptions()}
                    label={t('app.admin.store.product_category_form.select_parent_product_category')} />
            <FabButton type='submit'>{t('app.admin.store.product_category_form.save')}</FabButton>
          </>
      }
    </form>
  );
};
