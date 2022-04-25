# frozen_string_literal: true

json.extract! auth_provider, :id, :name, :status, :providable_type, :strategy_name
json.auth_provider_mappings_attributes auth_provider.auth_provider_mappings do |m|
  json.extract! m, :id, :local_model, :local_field, :api_field, :api_endpoint, :api_data_type, :transformation
end
