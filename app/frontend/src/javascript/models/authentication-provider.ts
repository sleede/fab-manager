export type ProvidableType = 'DatabaseProvider' | 'OAuth2Provider' | 'OpenIdConnectProvider' | 'SamlProvider';

export interface AuthenticationProvider {
  id?: number,
  name: string,
  status: 'active' | 'previous' | 'pending'
  providable_type: ProvidableType,
  strategy_name: string
  auth_provider_mappings_attributes: Array<AuthenticationProviderMapping>,
  providable_attributes?: OAuth2Provider | OpenIdConnectProvider | SamlProvider
}

export type mappingType = 'string' | 'text' | 'date' | 'integer' | 'boolean';

export interface AuthenticationProviderMapping {
  id?: number,
  _destroy?: boolean,
  local_model: 'user' | 'profile',
  local_field: string,
  api_field: string,
  api_endpoint: string,
  api_data_type: 'json',
  transformation: {
    type: mappingType,
    format: 'iso8601' | 'rfc2822' | 'rfc3339' | 'timestamp-s' | 'timestamp-ms',
    true_value: string,
    false_value: string,
    mapping: [
      {
        from: string,
        to: number|string
      }
    ]
  }
}

export interface OAuth2Provider {
  id?: string,
  base_url: string,
  token_endpoint: string,
  authorization_endpoint: string,
  profile_url: string,
  client_id: string,
  client_secret: string,
  scopes: string
}

export interface OpenIdConnectProvider {
  id?: string,
  issuer: string,
  discovery: boolean,
  client_auth_method?: 'basic' | 'jwks',
  scope?: Array<string>,
  prompt?: 'none' | 'login' | 'consent' | 'select_account',
  send_scope_to_token_endpoint?: string,
  client__identifier: string,
  client__secret: string,
  client__redirect_uri?: string,
  client__authorization_endpoint?: string,
  client__token_endpoint?: string,
  client__userinfo_endpoint?: string,
  client__jwks_uri?: string,
  client__end_session_endpoint?: string,
  profile_url?: string,
  extra_authorize_parameters?: string,
}

export interface SamlProvider {
  id?: string,
  sp_entity_id: string,
  idp_sso_service_url: string
  idp_cert_fingerprint: string,
  idp_cert: string,
  profile_url: string,
}

export interface MappingFields {
  user: Array<[string, mappingType]>,
  profile: Array<[string, mappingType]>
}

export interface ActiveProviderResponse extends AuthenticationProvider {
  previous_provider?: AuthenticationProvider
  mapping: Array<string>,
  link_to_sso_profile: string,
  link_to_sso_connect: string,
}
