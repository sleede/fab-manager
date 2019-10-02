json.partial! 'api/auth_providers/auth_provider', auth_provider: @provider
json.mapping @provider.sso_fields
json.link_to_sso_profile @provider.link_to_sso_profile
if @provider.providable_type == DatabaseProvider.name
  json.link_to_sso_connect '/#'
else
  json.link_to_sso_connect '/sso-redirect'
end

json.domain @provider.providable.domain if @provider.providable_type == OAuth2Provider.name
