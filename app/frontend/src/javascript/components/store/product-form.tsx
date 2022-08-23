import React, { useEffect, useState } from 'react';
import { useForm, useWatch } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import slugify from 'slugify';
import _ from 'lodash';
import { HtmlTranslate } from '../base/html-translate';
import { Product } from '../../models/product';
import { FormInput } from '../form/form-input';
import { FormSwitch } from '../form/form-switch';
import { FormSelect } from '../form/form-select';
import { FormChecklist } from '../form/form-checklist';
import { FormRichText } from '../form/form-rich-text';
import { FormFileUpload } from '../form/form-file-upload';
import { FormImageUpload } from '../form/form-image-upload';
import { FabButton } from '../base/fab-button';
import { FabAlert } from '../base/fab-alert';
import ProductCategoryAPI from '../../api/product-category';
import MachineAPI from '../../api/machine';
import ProductAPI from '../../api/product';
import { Plus } from 'phosphor-react';

interface ProductFormProps {
  product: Product,
  title: string,
  onSuccess: (product: Product) => void,
  onError: (message: string) => void,
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: number, label: string };

/**
 * Option format, expected by checklist
 */
type checklistOption = { value: number, label: string };

/**
 * Form component to create or update a product
 */
export const ProductForm: React.FC<ProductFormProps> = ({ product, title, onSuccess, onError }) => {
  const { t } = useTranslation('admin');

  const { handleSubmit, register, control, formState, setValue, reset } = useForm<Product>({ defaultValues: { ...product } });
  const output = useWatch<Product>({ control });
  const [isActivePrice, setIsActivePrice] = useState<boolean>(product.id && _.isFinite(product.amount) && product.amount > 0);
  const [productCategories, setProductCategories] = useState<selectOption[]>([]);
  const [machines, setMachines] = useState<checklistOption[]>([]);

  useEffect(() => {
    ProductCategoryAPI.index().then(data => {
      setProductCategories(buildSelectOptions(data));
    }).catch(onError);
    MachineAPI.index({ disabled: false }).then(data => {
      setMachines(buildChecklistOptions(data));
    }).catch(onError);
  }, []);

  /**
   * Convert the provided array of items to the react-select format
   */
  const buildSelectOptions = (items: Array<{ id?: number, name: string }>): Array<selectOption> => {
    return items.map(t => {
      return { value: t.id, label: t.name };
    });
  };

  /**
   * Convert the provided array of items to the checklist format
   */
  const buildChecklistOptions = (items: Array<{ id?: number, name: string }>): Array<checklistOption> => {
    return items.map(t => {
      return { value: t.id, label: t.name };
    });
  };

  /**
   * Callback triggered when the name has changed.
   */
  const handleNameChange = (event: React.ChangeEvent<HTMLInputElement>): void => {
    const name = event.target.value;
    const slug = slugify(name, { lower: true, strict: true });
    setValue('slug', slug);
  };

  /**
   * Callback triggered when is active price has changed.
   */
  const toggleIsActivePrice = (value: boolean) => {
    if (!value) {
      setValue('amount', null);
    }
    setIsActivePrice(value);
  };

  /**
   * Callback triggered when the form is submitted: process with the product creation or update.
   */
  const onSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    return handleSubmit((data: Product) => {
      saveProduct(data);
    })(event);
  };

  /**
   * Call product creation or update api
   */
  const saveProduct = (data: Product) => {
    if (product.id) {
      ProductAPI.update(data).then((res) => {
        reset(res);
        onSuccess(res);
      }).catch(onError);
    } else {
      ProductAPI.create(data).then((res) => {
        reset(res);
        onSuccess(res);
      }).catch(onError);
    }
  };

  /**
   * Add new product file
   */
  const addProductFile = () => {
    setValue('product_files_attributes', output.product_files_attributes.concat({}));
  };

  /**
   * Remove a product file
   */
  const handleRemoveProductFile = (i: number) => {
    return () => {
      const productFile = output.product_files_attributes[i];
      if (!productFile.id) {
        output.product_files_attributes.splice(i, 1);
        setValue('product_files_attributes', output.product_files_attributes);
      }
    };
  };

  /**
   * Add new product image
   */
  const addProductImage = () => {
    setValue('product_images_attributes', output.product_images_attributes.concat({
      is_main: output.product_images_attributes.length === 0
    }));
  };

  /**
   * Remove a product image
   */
  const handleRemoveProductImage = (i: number) => {
    return () => {
      const productImage = output.product_images_attributes[i];
      if (!productImage.id) {
        output.product_images_attributes.splice(i, 1);
        if (productImage.is_main) {
          setValue('product_images_attributes', output.product_images_attributes.map((image, k) => {
            if (k === 0) {
              return {
                ...image,
                is_main: true
              };
            }
            return image;
          }));
        } else {
          setValue('product_images_attributes', output.product_images_attributes);
        }
      } else {
        if (productImage.is_main) {
          let mainImage = false;
          setValue('product_images_attributes', output.product_images_attributes.map((image, k) => {
            if (i !== k && !mainImage) {
              mainImage = true;
              return {
                ...image,
                _destroy: i === k,
                is_main: true
              };
            }
            return {
              ...image,
              _destroy: i === k
            };
          }));
        }
      }
    };
  };

  /**
   * Remove main image in others product images
   */
  const handleSetMainImage = (i: number) => {
    return () => {
      if (output.product_images_attributes.length > 1) {
        setValue('product_images_attributes', output.product_images_attributes.map((image, k) => {
          if (i !== k) {
            return {
              ...image,
              is_main: false
            };
          }
          return {
            ...image,
            is_main: true
          };
        }));
      }
    };
  };

  return (
    <>
      <header>
        <h2>{title}</h2>
        <div className="grpBtn">
          <FabButton className="main-action-btn" onClick={handleSubmit(saveProduct)}>{t('app.admin.store.product_form.save')}</FabButton>
        </div>
      </header>
      <form className="product-form" onSubmit={onSubmit}>
        <div className="subgrid">
          <FormInput id="name"
                     register={register}
                     rules={{ required: true }}
                     formState={formState}
                     onChange={handleNameChange}
                     label={t('app.admin.store.product_form.name')}
                     className="span-7" />
          <FormInput id="sku"
                     register={register}
                     formState={formState}
                     label={t('app.admin.store.product_form.sku')}
                     className="span-3" />
        </div>
        <div className="subgrid">
          <FormInput id="slug"
                    register={register}
                    rules={{ required: true }}
                    formState={formState}
                    label={t('app.admin.store.product_form.slug')}
                    className='span-7' />
          <FormSwitch control={control}
                      id="is_active"
                      formState={formState}
                      label={t('app.admin.store.product_form.is_show_in_store')}
                      tooltip={t('app.admin.store.product_form.active_price_info')}
                      className='span-3' />
        </div>

        <hr />

        <div className="price-data">
          <div className="price-data-header">
            <h4 className='span-7'>{t('app.admin.store.product_form.price_and_rule_of_selling_product')}</h4>
            <FormSwitch control={control}
                        id="is_active_price"
                        label={t('app.admin.store.product_form.is_active_price')}
                        defaultValue={isActivePrice}
                        onChange={toggleIsActivePrice}
                        className='span-3' />
          </div>
          {isActivePrice && <div className="price-data-content">
            <FormInput id="amount"
                        type="number"
                        register={register}
                        rules={{ required: true, min: 0.01 }}
                        step={0.01}
                        formState={formState}
                        label={t('app.admin.store.product_form.price')} />
            <FormInput id="quantity_min"
                        type="number"
                        rules={{ required: true }}
                        register={register}
                        formState={formState}
                        label={t('app.admin.store.product_form.quantity_min')} />
          </div>}
        </div>

        <hr />

        <div>
          <h4>{t('app.admin.store.product_form.product_images')}</h4>
          <FabAlert level="warning">
            <HtmlTranslate trKey="app.admin.store.product_form.product_images_info" />
          </FabAlert>
          <div className="product-images">
            <div className="list">
              {output.product_images_attributes.map((image, i) => (
                <FormImageUpload key={i}
                                 defaultImage={image}
                                 id={`product_images_attributes[${i}]`}
                                 accept="image/*"
                                 size="small"
                                 register={register}
                                 setValue={setValue}
                                 formState={formState}
                                 className={image._destroy ? 'hidden' : ''}
                                 mainOption={true}
                                 onFileRemove={handleRemoveProductImage(i)}
                                 onFileIsMain={handleSetMainImage(i)}
                                />
              ))}
            </div>
          <FabButton
            onClick={addProductImage}
            className='is-info'
            icon={<Plus size={24} />}>
            {t('app.admin.store.product_form.add_product_image')}
          </FabButton>
          </div>
        </div>

        <hr />

        <div>
          <h4>{t('app.admin.store.product_form.assigning_category')}</h4>
          <FabAlert level="warning">
            <HtmlTranslate trKey="app.admin.store.product_form.assigning_category_info" />
          </FabAlert>
          <FormSelect options={productCategories}
                      control={control}
                      id="product_category_id"
                      formState={formState}
                      label={t('app.admin.store.product_form.linking_product_to_category')} />
        </div>

        <hr />

        <div>
          <h4>{t('app.admin.store.product_form.assigning_machines')}</h4>
          <FabAlert level="warning">
            <HtmlTranslate trKey="app.admin.store.product_form.assigning_machines_info" />
          </FabAlert>
          <FormChecklist options={machines}
                          control={control}
                          id="machine_ids"
                          formState={formState} />
        </div>

        <hr />

        <div>
          <h4>{t('app.admin.store.product_form.product_description')}</h4>
          <FabAlert level="warning">
            <HtmlTranslate trKey="app.admin.store.product_form.product_description_info" />
          </FabAlert>
          <FormRichText control={control}
                        paragraphTools={true}
                        limit={1000}
                        id="description" />
        </div>

        <hr />

        <div>
          <h4>{t('app.admin.store.product_form.product_files')}</h4>
          <FabAlert level="warning">
            <HtmlTranslate trKey="app.admin.store.product_form.product_files_info" />
          </FabAlert>
          <div className="product-documents">
            <div className="list">
              {output.product_files_attributes.map((file, i) => (
                <FormFileUpload key={i}
                                defaultFile={file}
                                id={`product_files_attributes[${i}]`}
                                accept="application/pdf"
                                register={register}
                                setValue={setValue}
                                formState={formState}
                                className={file._destroy ? 'hidden' : ''}
                                onFileRemove={handleRemoveProductFile(i)}/>
              ))}
            </div>
            <FabButton
              onClick={addProductFile}
              className='is-info'
              icon={<Plus size={24} />}>
              {t('app.admin.store.product_form.add_product_file')}
            </FabButton>
          </div>
        </div>

        <div className="main-actions">
          <FabButton type="submit" className="main-action-btn">{t('app.admin.store.product_form.save')}</FabButton>
        </div>
      </form>
    </>
  );
};
