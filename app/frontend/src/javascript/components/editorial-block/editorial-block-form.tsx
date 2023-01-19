import * as React from 'react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { Control, FormState, UseFormRegister } from 'react-hook-form';
import { FormSwitch } from '../form/form-switch';
import { FormRichText } from '../form/form-rich-text';
import { FormInput } from '../form/form-input';

interface EditorialBlockFormProps<TFieldValues> {
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues>,
  formState: FormState<TFieldValues>,
  info?: string
}

// regular expression to validate the input fields
const urlRegex = /^(https?:\/\/)([^.]+)\.(.{2,30})(\/.*)*\/?$/;

/**
 * Allows to create a formatted text and optional cta button in a form block, to be included in a resource form managed by react-hook-form.
 */
export const EditorialBlockForm = <TFieldValues extends FieldValues>({ register, control, formState, info }: EditorialBlockFormProps<TFieldValues>) => {
  const { t } = useTranslation('admin');

  const [isActiveTextBlock, setIsActiveTextBlock] = useState<boolean>(false);
  const [isActiveCta, setIsActiveCta] = useState<boolean>(false);

  /** Callback triggered when the text block switch has changed. */
  const toggleTextBlockSwitch = (value: boolean) => {
    setIsActiveTextBlock(value);
  };

  /** Callback triggered when the CTA switch has changed. */
  const toggleTextBlockCta = (value: boolean) => {
    setIsActiveCta(value);
  };

  return (
    <>
      <header>
        <p className="title">{t('app.admin.editorial_block_form.title')}</p>
        {info && <p className="description">{info}</p>}
      </header>

      <div className="content">
        <FormSwitch id="active_text_block" control={control}
          onChange={toggleTextBlockSwitch} formState={formState}
          defaultValue={isActiveTextBlock}
          label={t('app.admin.editorial_block_form.switch')} />

        {/* TODO: error message if empty */}
        <FormRichText id="text_block"
                      control={control}
                      heading
                      limit={280}
                      rules={{ required: isActiveTextBlock }}
                      disabled={!isActiveTextBlock} />

        {isActiveTextBlock && <>
          <FormSwitch id="active_cta" control={control}
            onChange={toggleTextBlockCta} formState={formState}
            label={t('app.admin.editorial_block_form.cta_switch')} />

          {isActiveCta && <>
            <FormInput id="cta_label"
                      register={register}
                      rules={{ required: isActiveCta }}
                      maxLength={40}
                      label={t('app.admin.editorial_block_form.cta_label')} />
            <FormInput id="cta_url"
                      register={register}
                      rules={{ required: isActiveCta, pattern: urlRegex }}
                      label={t('app.admin.editorial_block_form.cta_url')} />
          </>}
        </>}
      </div>
    </>
  );
};
