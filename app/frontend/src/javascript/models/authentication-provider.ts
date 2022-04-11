export interface AuthenticationProvider {
  id?: number,
  name: string,
  status: 'active' | 'previous' | 'pending'
  providable_type: 'DatabaseProvider' | 'OAuth2Provider' | 'OpenIdConnectProvider',
  strategy_name: string
  auth_provider_mappings_attributes: Array<AuthenticationProviderMapping>,
  providable_attributes?: OAuth2Provider | OpenIdConnectProvider
}

export type mappingType = 'string' | 'text' | 'date' | 'integer' | 'boolean';

export interface AuthenticationProviderMapping {
  id?: number,
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
    mapping: {
      from: string,
      to: number|string
    }
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
  client_auth_method?: string,
  scope?: string,
  response_type?: 'code' | 'id_token',
  response_mode?: 'query' | 'fragment' | 'form_post' | 'web_message',
  display?: 'page' | 'popup' | 'touch' | 'wap',
  prompt?: 'none' | 'login' | 'consent' | 'select_account',
  send_scope_to_token_endpoint?: string,
  post_logout_redirect_uri?: string,
  uid_field?: string,
  extra_authorize_params?: string,
  allow_authorize_params?: string,
  client__identifier: string,
  client__secret: string,
  client__redirect_uri?: string,
  client__scheme: 'http' | 'https',
  client__host: string,
  client__port: number,
  client__authorization_endpoint?: string,
  client__token_endpoint?: string,
  client__userinfo_endpoint?: string,
  client__jwks_uri?: string,
  client__end_session_endpoint?: string,
  profile_url?: string
}

export interface MappingFields {
  user: Array<[string, mappingType]>,
  profile: Array<[string, mappingType]>
}
