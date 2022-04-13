import React from 'react';
import { UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import { FormInput } from '../form/form-input';
import { FormSelect } from '../form/form-select';
import { Control } from 'react-hook-form/dist/types/form';
import { HtmlTranslate } from '../base/html-translate';
import { OpenIdConnectProvider } from '../../models/authentication-provider';

interface OpenidConnectFormProps<TFieldValues, TContext extends object> {
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues, TContext>,
  currentFormValues: OpenIdConnectProvider
}

export const OpenidConnectForm = <TFieldValues extends FieldValues, TContext extends object>({ register, control, currentFormValues }: OpenidConnectFormProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('admin');

  // regular expression to validate the the input fields
  const endpointRegex = /^\/?([-._~:?#[\]@!$&'()*+,;=%\w]+\/?)*$/;
  const urlRegex = /^(https?:\/\/)([\da-z.-]+)\.([-a-z0-9.]{2,30})([/\w .-]*)*\/?$/;

  return (
    <div className="openid-connect-form">
      <hr/>
      <FormInput id="providable_attributes.issuer"
                 register={register}
                 label={t('app.admin.authentication.openid_connect_form.issuer')}
                 placeholder="https://sso.exemple.com"
                 tooltip={t('app.admin.authentication.openid_connect_form.issuer_help')}
                 rules={{ required: true, pattern: urlRegex }} />
      <FormSelect id="providable_attributes.discovery"
                  label={t('app.admin.authentication.openid_connect_form.discovery')}
                  tooltip={t('app.admin.authentication.openid_connect_form.discovery_help')}
                  options={[
                    { value: true, label: t('app.admin.authentication.openid_connect_form.discovery_enabled') },
                    { value: false, label: t('app.admin.authentication.openid_connect_form.discovery_disabled') }
                  ]}
                  valueDefault={true}
                  control={control} />
      <FormSelect id="providable_attributes.client_auth_method"
                  label={t('app.admin.authentication.openid_connect_form.client_auth_method')}
                  tooltip={t('app.admin.authentication.openid_connect_form.client_auth_method_help')}
                  options={[
                    { value: 'basic', label: t('app.admin.authentication.openid_connect_form.client_auth_method_basic') },
                    { value: 'jwks', label: t('app.admin.authentication.openid_connect_form.client_auth_method_jwks') }
                  ]}
                  valueDefault={'basic'}
                  control={control} />
      <FormInput id="providable_attributes.scope"
                 register={register}
                 label={t('app.admin.authentication.openid_connect_form.scope')}
                 placeholder="openid,profile,email"
                 tooltip={t('app.admin.authentication.openid_connect_form.scope_help')} />
      <FormSelect id="providable_attributes.response_type"
                  label={t('app.admin.authentication.openid_connect_form.response_type')}
                  tooltip={t('app.admin.authentication.openid_connect_form.response_type_help')}
                  options={[
                    { value: 'code', label: t('app.admin.authentication.openid_connect_form.response_type_code') },
                    { value: 'id_token', label: t('app.admin.authentication.openid_connect_form.response_type_id_token') }
                  ]}
                  valueDefault={'code'}
                  control={control} />
      <FormSelect id="providable_attributes.response_mode"
                  label={t('app.admin.authentication.openid_connect_form.response_mode')}
                  tooltip={<HtmlTranslate trKey="app.admin.authentication.openid_connect_form.response_mode_help_html" />}
                  options={[
                    { value: 'query', label: t('app.admin.authentication.openid_connect_form.response_mode_query') },
                    { value: 'fragment', label: t('app.admin.authentication.openid_connect_form.response_mode_fragment') },
                    { value: 'form_post', label: t('app.admin.authentication.openid_connect_form.response_mode_form_post') },
                    { value: 'web_message', label: t('app.admin.authentication.openid_connect_form.response_mode_web_message') }
                  ]}
                  clearable
                  control={control} />
      <FormSelect id="providable_attributes.display"
                  label={t('app.admin.authentication.openid_connect_form.display')}
                  tooltip={<HtmlTranslate trKey="app.admin.authentication.openid_connect_form.display_help_html" />}
                  options={[
                    { value: 'page', label: t('app.admin.authentication.openid_connect_form.display_page') },
                    { value: 'popup', label: t('app.admin.authentication.openid_connect_form.display_popup') },
                    { value: 'touch', label: t('app.admin.authentication.openid_connect_form.display_touch') },
                    { value: 'wap', label: t('app.admin.authentication.openid_connect_form.display_wap') }
                  ]}
                  clearable
                  control={control} />
      <FormSelect id="providable_attributes.prompt"
                  label={t('app.admin.authentication.openid_connect_form.prompt')}
                  tooltip={<HtmlTranslate trKey="app.admin.authentication.openid_connect_form.prompt_help_html" />}
                  options={[
                    { value: 'none', label: t('app.admin.authentication.openid_connect_form.prompt_none') },
                    { value: 'login', label: t('app.admin.authentication.openid_connect_form.prompt_login') },
                    { value: 'consent', label: t('app.admin.authentication.openid_connect_form.prompt_consent') },
                    { value: 'select_account', label: t('app.admin.authentication.openid_connect_form.prompt_select_account') }
                  ]}
                  clearable
                  control={control} />
      <FormSelect id="providable_attributes.send_scope_to_token_endpoint"
                  label={t('app.admin.authentication.openid_connect_form.send_scope_to_token_endpoint')}
                  tooltip={t('app.admin.authentication.openid_connect_form.send_scope_to_token_endpoint_help')}
                  options={[
                    { value: false, label: t('app.admin.authentication.openid_connect_form.send_scope_to_token_endpoint_false') },
                    { value: true, label: t('app.admin.authentication.openid_connect_form.send_scope_to_token_endpoint_true') }
                  ]}
                  valueDefault={true}
                  control={control} />
      <FormInput id="providable_attributes.uid_field"
                 label={t('app.admin.authentication.openid_connect_form.uid_field')}
                 tooltip={t('app.admin.authentication.openid_connect_form.uid_field_help')}
                 defaultValue="sub"
                 placeholder="user_id"
                 register={register} />
      <FormInput id="providable_attributes.profile_url"
                 register={register}
                 placeholder="https://sso.exemple.com/my-account"
                 label={t('app.admin.authentication.openid_connect_form.profile_edition_url')}
                 tooltip={t('app.admin.authentication.openid_connect_form.profile_edition_url_help')}
                 rules={{ pattern: urlRegex }} />
      <h4>{t('app.admin.authentication.openid_connect_form.client_options')}</h4>
      <FormInput id="providable_attributes.client__identifier"
                 label={t('app.admin.authentication.openid_connect_form.client__identifier')}
                 rules={{ required: true }}
                 register={register} />
      <FormInput id="providable_attributes.client__secret"
                 label={t('app.admin.authentication.openid_connect_form.client__secret')}
                 rules={{ required: true }}
                 register={register} />
      {!currentFormValues?.discovery && <div className="client-options-without-discovery">
        <FormInput id="providable_attributes.client__authorization_endpoint"
                   label={t('app.admin.authentication.openid_connect_form.client__authorization_endpoint')}
                   placeholder="/authorize"
                   rules={{ required: !currentFormValues?.discovery, pattern: endpointRegex }}
                   register={register} />
        <FormInput id="providable_attributes.client__token_endpoint"
                   label={t('app.admin.authentication.openid_connect_form.client__token_endpoint')}
                   placeholder="/token"
                   rules={{ required: !currentFormValues?.discovery, pattern: endpointRegex }}
                   register={register} />
        <FormInput id="providable_attributes.client__userinfo_endpoint"
                   label={t('app.admin.authentication.openid_connect_form.client__userinfo_endpoint')}
                   placeholder="/userinfo"
                   rules={{ required: !currentFormValues?.discovery, pattern: endpointRegex }}
                   register={register} />
        {currentFormValues?.client_auth_method === 'jwks' && <FormInput id="providable_attributes.client__jwks_uri"
                   label={t('app.admin.authentication.openid_connect_form.client__jwks_uri')}
                   rules={{ required: currentFormValues.client_auth_method === 'jwks', pattern: endpointRegex }}
                   placeholder="/jwk"
                   register={register} />}
        <FormInput id="providable_attributes.client__end_session_endpoint"
                   label={t('app.admin.authentication.openid_connect_form.client__end_session_endpoint')}
                   tooltip={t('app.admin.authentication.openid_connect_form.client__end_session_endpoint_help')}
                   rules={{ pattern: endpointRegex }}
                   register={register} />
      </div>}
    </div>
  );
};
