import { useEffect, useState } from 'react';
import * as React from 'react';
import { Path, UseFormRegister } from 'react-hook-form';
import { FieldValues } from 'react-hook-form/dist/types/fields';
import { useTranslation } from 'react-i18next';
import { FormInput } from '../form/form-input';
import { FormSelect } from '../form/form-select';
import { Control, FormState, UnpackNestedValue, UseFormSetValue } from 'react-hook-form/dist/types/form';
import { HtmlTranslate } from '../base/html-translate';
import { OpenIdConnectProvider } from '../../models/authentication-provider';
import SsoClient from '../../api/external/sso';
import { FieldPathValue } from 'react-hook-form/dist/types/path';
import { FormMultiSelect } from '../form/form-multi-select';
import { difference } from 'lodash';

interface OpenidConnectFormProps<TFieldValues, TContext extends object> {
  register: UseFormRegister<TFieldValues>,
  control: Control<TFieldValues, TContext>,
  currentFormValues: OpenIdConnectProvider,
  formState: FormState<TFieldValues>,
  setValue: UseFormSetValue<TFieldValues>,
}

/**
 * Partial form to fill the OpenID Connect (OIDC) settings for a new/existing authentication provider.
 */
export const OpenidConnectForm = <TFieldValues extends FieldValues, TContext extends object>({ register, control, currentFormValues, formState, setValue }: OpenidConnectFormProps<TFieldValues, TContext>) => {
  const { t } = useTranslation('admin');

  // saves the state of the discovery endpoint
  const [discoveryAvailable, setDiscoveryAvailable] = useState<boolean>(false);
  const [scopesAvailable, setScopesAvailable] = useState<string[]>(null);
  // this is a workaround for https://github.com/JedWatson/react-select/issues/1879
  const [selectKey, setSelectKey] = useState<number>(0);

  // when we have detected a discovery endpoint, we mark it as available
  useEffect(() => {
    setValue(
      'providable_attributes.discovery' as Path<TFieldValues>,
      discoveryAvailable as UnpackNestedValue<FieldPathValue<TFieldValues, Path<TFieldValues>>>
    );
  }, [discoveryAvailable]);

  // this will force the scope "select" to re-fetch the options
  useEffect(() => {
    setSelectKey(selectKey + 1);
  }, [scopesAvailable]);

  // when the component is mounted, we try to discover the discovery endpoint for the current configuration (if any)
  useEffect(() => {
    checkForDiscoveryEndpoint({ target: { value: currentFormValues?.issuer } } as React.ChangeEvent<HTMLInputElement>);
  }, []);

  // regular expression to validate the input fields
  const endpointRegex = /^\/?([-._~:?#[\]@!$&'()*+,;=%\w]+\/?)*$/;
  const urlRegex = /^(https?:\/\/)([^.]+)\.(.{2,30})(\/.*)*\/?$/;

  /**
   * If the discovery endpoint is available, the user will be able to choose to use it or not.
   * Otherwise, he will need to end the client configuration manually.
   */
  const buildDiscoveryOptions = () => {
    if (discoveryAvailable) {
      return [
        { value: true, label: t('app.admin.authentication.openid_connect_form.discovery_enabled') },
        { value: false, label: t('app.admin.authentication.openid_connect_form.discovery_disabled') }
      ];
    }

    return [
      { value: false, label: t('app.admin.authentication.openid_connect_form.discovery_disabled') }
    ];
  };

  /**
   * Return the list of scopes that are available for the current configuration.
   * The resulting list is provided through the callback parameter.
   */
  const loadScopes = (inputValue: string, callback: (options: Array<{ value: string, label: string }>) => void): void => {
    const current = currentFormValues?.scope || [];
    if (scopesAvailable) {
      // add custom scopes to the list of available scopes
      const unlisted = difference(current, scopesAvailable);
      callback(scopesAvailable.concat(unlisted).map(scope => ({ value: scope, label: scope })));
    } else {
      callback(current.map(scope => ({ value: scope, label: scope })));
    }
  };

  /**
   * Callback that check for the existence of the .well-known/openid-configuration endpoint, for the given issuer.
   * This callback is triggered when the user changes the issuer field.
   */
  const checkForDiscoveryEndpoint = (e: React.ChangeEvent<HTMLInputElement>) => {
    SsoClient.openIdConfiguration(e.target.value).then((configuration) => {
      setDiscoveryAvailable(true);
      setScopesAvailable(configuration.scopes_supported);
    }).catch(() => {
      setDiscoveryAvailable(false);
      setScopesAvailable(null);
    });
  };

  return (
    <div className="openid-connect-form">
      <hr/>
      <FormInput id="providable_attributes.issuer"
                 register={register}
                 label={t('app.admin.authentication.openid_connect_form.issuer')}
                 placeholder="https://sso.exemple.com"
                 tooltip={t('app.admin.authentication.openid_connect_form.issuer_help')}
                 rules={{ required: true, pattern: urlRegex }}
                 onChange={checkForDiscoveryEndpoint}
                 debounce={400}
                 warning={!discoveryAvailable && { message: t('app.admin.authentication.openid_connect_form.discovery_unavailable') } }
                 formState={formState} />
      <FormSelect id="providable_attributes.discovery"
                  label={t('app.admin.authentication.openid_connect_form.discovery')}
                  tooltip={t('app.admin.authentication.openid_connect_form.discovery_help')}
                  options={buildDiscoveryOptions()}
                  valueDefault={discoveryAvailable}
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
      <FormMultiSelect id="providable_attributes.scope"
                       label={t('app.admin.authentication.openid_connect_form.scope')}
                       tooltip={<HtmlTranslate trKey="app.admin.authentication.openid_connect_form.scope_help_html" />}
                       loadOptions={loadScopes}
                       selectKey={selectKey.toString()}
                       creatable
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
      <FormInput id="providable_attributes.profile_url"
                 register={register}
                 placeholder="https://sso.exemple.com/my-account"
                 label={t('app.admin.authentication.openid_connect_form.profile_edition_url')}
                 tooltip={t('app.admin.authentication.openid_connect_form.profile_edition_url_help')}
                 rules={{ required: false, pattern: urlRegex }} />
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
