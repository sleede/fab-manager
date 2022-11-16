import { useEffect, useState } from 'react';
import * as React from 'react';
import { SubmitHandler, useForm, useWatch } from 'react-hook-form';
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
import { FabButton } from '../base/fab-button';
import { FabAlert } from '../base/fab-alert';
import ProductCategoryAPI from '../../api/product-category';
import MachineAPI from '../../api/machine';
import ProductAPI from '../../api/product';
import { ProductStockForm } from './product-stock-form';
import { CloneProductModal } from './clone-product-modal';
import ProductLib from '../../lib/product';
import { UnsavedFormAlert } from '../form/unsaved-form-alert';
import { UIRouter } from '@uirouter/angularjs';
import { SelectOption, ChecklistOption } from '../../models/select';
import { FormMultiFileUpload } from '../form/form-multi-file-upload';
import { FormMultiImageUpload } from '../form/form-multi-image-upload';
import { AdvancedAccountingForm } from '../accounting/advanced-accounting-form';
import { FabTabs } from '../base/fab-tabs';

interface ProductFormProps {
  product: Product,
  title: string,
  onSuccess: (product: Product) => void,
  onError: (message: string) => void,
  uiRouter: UIRouter
}

/**
 * Form component to create or update a product
 */
export const ProductForm: React.FC<ProductFormProps> = ({ product, title, onSuccess, onError, uiRouter }) => {
  const { t } = useTranslation('admin');

  const { handleSubmit, register, control, formState, setValue, reset } = useForm<Product>({ defaultValues: { ...product } });
  const output = useWatch<Product>({ control });
  const [isActivePrice, setIsActivePrice] = useState<boolean>(product.id && _.isFinite(product.amount));
  const [productCategories, setProductCategories] = useState<SelectOption<number, string | JSX.Element>[]>([]);
  const [machines, setMachines] = useState<ChecklistOption<number>[]>([]);
  const [openCloneModal, setOpenCloneModal] = useState<boolean>(false);
  const [saving, setSaving] = useState<boolean>(false);

  useEffect(() => {
    ProductCategoryAPI.index().then(data => {
      setProductCategories(buildSelectOptions(ProductLib.sortCategories(data)));
    }).catch(onError);
    MachineAPI.index({ disabled: false }).then(data => {
      setMachines(buildChecklistOptions(data));
    }).catch(onError);
  }, []);

  /**
   * Convert the provided array of items to the react-select format
   */
  const buildSelectOptions = (items: Array<{ id?: number, name: string, parent_id?: number }>): Array<SelectOption<number, string | JSX.Element>> => {
    return items.map(t => {
      return {
        value: t.id,
        label: t.parent_id
          ? <span className='u-leading-space'>{t.name}</span>
          : t.name
      };
    });
  };

  /**
   * Convert the provided array of items to the checklist format
   */
  const buildChecklistOptions = (items: Array<{ id?: number, name: string }>): Array<ChecklistOption<number>> => {
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
   * Callback triggered when the user toggles the visibility of the product in the store.
   */
  const handleIsActiveChanged = (value: boolean): void => {
    if (value) {
      setValue('is_active_price', true);
      setIsActivePrice(true);
    }
  };

  /**
   * Callback triggered when is active price has changed.
   */
  const toggleIsActivePrice = (value: boolean) => {
    if (!value) {
      setValue('amount', null);
      setValue('is_active', false);
    }
    setIsActivePrice(value);
  };

  /**
   * Callback triggered when the form is submitted: process with the product creation or update.
   */
  const onSubmit: SubmitHandler<Product> = (data: Product) => {
    saveProduct(data);
  };

  /**
   * Call product creation or update api
   */
  const saveProduct = (data: Product) => {
    setSaving(true);
    if (product.id) {
      ProductAPI.update(data).then((res) => {
        reset(res);
        setSaving(false);
        onSuccess(res);
      }).catch(e => {
        setSaving(false);
        onError(e);
      });
    } else {
      ProductAPI.create(data).then((res) => {
        reset(res);
        onSuccess(res);
      }).catch(e => {
        setSaving(false);
        onError(e);
      });
    }
  };

  /**
   * Toggle clone product modal
   */
  const toggleCloneModal = () => {
    setOpenCloneModal(!openCloneModal);
  };

  /**
   * This function render the content of the 'products settings' tab
   */
  const renderSettingsTab = () => (
    <section>
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
                    onChange={handleIsActiveChanged}
                    className='span-3' />
      </div>

      <hr />

      <div className="price-data">
        <div className="header-switch">
          <h4>{t('app.admin.store.product_form.price_and_rule_of_selling_product')}</h4>
          <FormSwitch control={control}
                      id="is_active_price"
                      label={t('app.admin.store.product_form.is_active_price')}
                      defaultValue={isActivePrice}
                      onChange={toggleIsActivePrice} />
        </div>
        {isActivePrice && <div className="price-data-content">
          <FormInput id="amount"
                     type="number"
                     register={register}
                     rules={{ required: isActivePrice, min: 0 }}
                     step={0.01}
                     formState={formState}
                     label={t('app.admin.store.product_form.price')}
                     nullable />
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
        <FormMultiImageUpload setValue={setValue}
                              addButtonLabel={t('app.admin.store.product_form.add_product_image')}
                              register={register}
                              control={control}
                              id="product_images_attributes"
                              className="product-images" />
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
                      heading
                      bulletList
                      blockquote
                      link
                      limit={6000}
                      id="description" />
      </div>

      <hr />

      <div>
        <h4>{t('app.admin.store.product_form.product_files')}</h4>
        <FabAlert level="warning">
          <HtmlTranslate trKey="app.admin.store.product_form.product_files_info" />
        </FabAlert>
        <FormMultiFileUpload setValue={setValue}
                             addButtonLabel={t('app.admin.store.product_form.add_product_file')}
                             control={control}
                             accept="application/pdf"
                             register={register}
                             id="product_files_attributes"
                             className="product-documents" />
      </div>

      <hr />

      <AdvancedAccountingForm register={register} onError={onError} />

      <div className="main-actions">
        <FabButton type="submit" className="main-action-btn" disabled={saving}>
          {!saving && t('app.admin.store.product_form.save')}
          {saving && <i className="fa fa-spinner fa-pulse fa-fw" />}
        </FabButton>
      </div>
    </section>
  );

  return (
    <>
      <header>
        <h2>{title}</h2>
        <div className="grpBtn">
          {product.id &&
            <>
              <FabButton onClick={toggleCloneModal}>{t('app.admin.store.product_form.clone')}</FabButton>
              <CloneProductModal isOpen={openCloneModal} toggleModal={toggleCloneModal} product={product} onSuccess={onSuccess} onError={onError} />
            </>
          }
          <FabButton className="main-action-btn" onClick={handleSubmit(saveProduct)} disabled={saving}>
            {!saving && t('app.admin.store.product_form.save')}
            {saving && <i className="fa fa-spinner fa-pulse fa-fw text-white" />}
          </FabButton>
        </div>
      </header>
      <form className="product-form" onSubmit={handleSubmit(onSubmit)}>
        <UnsavedFormAlert uiRouter={uiRouter} formState={formState} />
        <FabTabs tabs={[
          {
            id: 'settings',
            title: t('app.admin.store.product_form.product_parameters'),
            content: renderSettingsTab()
          },
          {
            id: 'stock',
            title: t('app.admin.store.product_form.stock_management'),
            content: <ProductStockForm currentFormValues={output as Product}
                                       register={register}
                                       control={control}
                                       formState={formState}
                                       setValue={setValue}
                                       onError={onError}
                                       onSuccess={onSuccess} />
          }
        ]} />
      </form>
    </>
  );
};
