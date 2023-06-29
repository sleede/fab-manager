# frozen_string_literal: true

json.array!(@project_categories) do |project_category|
  json.extract! project_category, :id, :name
end
