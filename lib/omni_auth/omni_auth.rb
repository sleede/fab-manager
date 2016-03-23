active_provider = AuthProvider.active

if active_provider.providable_type != DatabaseProvider.name
  require_relative "strategies/sso_#{active_provider.provider_type}_provider"
end