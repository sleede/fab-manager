import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Control, FormState, UseFormRegister } from 'react-hook-form';
import { FormSwitch } from '../form/form-switch';
import { FormRichText } from '../form/form-rich-text';
import { FormInput } from '../form/form-input';
import { SettingName, SettingValue } from '../../models/setting';

export type EditorialKeys = 'active_text_block' | 'text_block' | 'active_cta' | 'cta_label' | 'cta_url';

interface EditorialBlockFormProps {
  register: UseFormRegister<Record<SettingName, SettingValue>>,
  control: Control<Record<SettingName, SettingValue>>,
  formState: FormState<Record<SettingName, SettingValue>>,
  info?: string
  keys: Record<EditorialKeys, SettingName>
}

// regular expression to validate the input fields
const urlRegex = /^(https?:\/\/)([^.]+)\.(.{2,30})(\/.*)*\/?$/;

/**
 * Allows to create a formatted text and optional cta button in a form block, to be included in a resource form managed by react-hook-form.
 */
export const EditorialBlockForm: React.FC<EditorialBlockFormProps> = ({ register, control, formState, info, keys }) => {
  const { t } = useTranslation('admin');

  const [isActiveTextBlock, setIsActiveTextBlock] = useState<boolean>(false);
  const [isActiveCta, setIsActiveCta] = useState<boolean>(false);

  /** Set correct values for switches when formState changes */
  useEffect(() => {
    setIsActiveTextBlock(control._formValues[keys.active_text_block]);
    setIsActiveCta(control._formValues[keys.active_cta]);
  }, [control._formValues]);

  /** Callback triggered when the text block switch has changed. */
  const toggleTextBlockSwitch = (value: boolean) => setIsActiveTextBlock(value);

  /** Callback triggered when the CTA switch has changed. */
  const toggleTextBlockCta = (value: boolean) => setIsActiveCta(value);

  return (
    <>
      <header>
        <p className="title">{t('app.admin.editorial_block_form.title')}</p>
        {info && <p className="description">{info}</p>}
      </header>

      <div className="content" data-testid="editorial-block-form">
        <FormSwitch id={keys.active_text_block} control={control}
          onChange={toggleTextBlockSwitch} formState={formState}
          defaultValue={isActiveTextBlock}
          label={t('app.admin.editorial_block_form.switch')} />

        <FormRichText id={keys.text_block}
                      label={t('app.admin.editorial_block_form.content')}
                      control={control}
                      formState={formState}
                      heading
                      limit={280}
                      rules={{ required: { value: isActiveTextBlock, message: t('app.admin.editorial_block_form.content_is_required') } }}
                      disabled={!isActiveTextBlock} />

        {isActiveTextBlock && <>
          <FormSwitch id={keys.active_cta} control={control}
            onChange={toggleTextBlockCta} formState={formState}
            label={t('app.admin.editorial_block_form.cta_switch')} />

          {isActiveCta && <>
            <FormInput id={keys.cta_label}
                      register={register}
                      formState={formState}
                      rules={{ required: { value: isActiveCta, message: t('app.admin.editorial_block_form.label_is_required') } }}
                      maxLength={40}
                      label={t('app.admin.editorial_block_form.cta_label')} />
            <FormInput id={keys.cta_url}
                      register={register}
                      formState={formState}
                      rules={{
                        required: { value: isActiveCta, message: t('app.admin.editorial_block_form.url_is_required') },
                        pattern: { value: urlRegex, message: t('app.admin.editorial_block_form.url_must_be_safe') }
                      }}
                      label={t('app.admin.editorial_block_form.cta_url')} />
          </>}
        </>}
      </div>
    </>
  );
};
