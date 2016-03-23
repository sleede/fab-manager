json.array!(@providers) do |provider|
  json.partial! 'api/auth_providers/auth_provider', auth_provider: provider
end
