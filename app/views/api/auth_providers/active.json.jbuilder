json.partial! 'api/auth_providers/auth_provider', auth_provider: @provider
json.mapping @provider.sso_fields
json.link_to_sso_profile @provider.link_to_sso_profile
if @provider.providable_type == DatabaseProvider.name
  json.link_to_sso_connect '/#'
else
  json.link_to_sso_connect user_omniauth_authorize_path(@provider.strategy_name.to_sym)
end

if @provider.providable_type == OAuth2Provider.name
  json.domain @provider.providable.domain
end