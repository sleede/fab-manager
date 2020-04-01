# frozen_string_literal: true

# OpenAPI provides an way for external apps to use Fab-manager's data through a REST API.
module OpenAPI
  def self.table_name_prefix
    'open_api_'
  end
end
