# frozen_string_literal: true

json.array! @profile_custom_fields do |profile_custom_field|
  json.partial! 'api/profile_custom_fields/profile_custom_field', profile_custom_field: profile_custom_field
end
