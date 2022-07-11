import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import Select from 'react-select';
import slugify from 'slugify';
import { FabInput } from '../base/fab-input';
import { ProductCategory } from '../../models/product-category';

interface ProductCategoryFormProps {
  productCategories: Array<ProductCategory>,
  productCategory?: ProductCategory,
  onChange: (field: string, value: string | number) => void,
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: number, label: string };

/**
 * Form to set create/edit supporting documents type
 */
export const ProductCategoryForm: React.FC<ProductCategoryFormProps> = ({ productCategories, productCategory, onChange }) => {
  const { t } = useTranslation('admin');

  // filter all first level product categorie
  const parents = productCategories.filter(c => !c.parent_id);

  const [slug, setSlug] = useState<string>(productCategory?.slug || '');

  /**
   * Return the default first level product category, formatted to match the react-select format
   */
  const defaultValue = { value: productCategory?.parent_id, label: productCategory?.name };

  /**
   * Convert all parents to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return parents.map(t => {
      return { value: t.id, label: t.name };
    });
  };

  /**
   * Callback triggered when the selection of parent product category has changed.
   */
  const handleCategoryParentChange = (option: selectOption): void => {
    onChange('parent_id', option.value);
  };

  /**
   * Callback triggered when the name has changed.
   */
  const handleNameChange = (value: string): void => {
    onChange('name', value);
    const _slug = slugify(value, { lower: true });
    setSlug(_slug);
    onChange('slug', _slug);
  };

  /**
   * Callback triggered when the slug has changed.
   */
  const handleSlugChange = (value: string): void => {
    onChange('slug', value);
  };

  return (
    <div className="product-category-form">
      <form name="productCategoryForm">
        <div className="field">
          <FabInput id="product_category_name"
            icon={<i className="fa fa-edit" />}
            defaultValue={productCategory?.name || ''}
            placeholder={t('app.admin.store.product_category_form.name')}
            onChange={handleNameChange}
            debounce={200}
            required/>
        </div>
        <div className="field">
          <FabInput id="product_category_slug"
            icon={<i className="fa fa-edit" />}
            defaultValue={slug}
            placeholder={t('app.admin.store.product_category_form.slug')}
            onChange={handleSlugChange}
            debounce={200}
            required/>
        </div>
        <div className="field">
          <Select defaultValue={defaultValue}
            placeholder={t('app.admin.store.product_category_form.select_parent_product_category')}
            onChange={handleCategoryParentChange}
            options={buildOptions()} />
        </div>
      </form>
    </div>
  );
};
