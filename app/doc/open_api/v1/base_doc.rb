# frozen_string_literal: true

# parent class for openAPI documentation
class OpenAPI::V1::BaseDoc < OpenAPI::ApplicationDoc
  API_VERSION = 'v1'
  FORMATS = ['json'].freeze
  PER_PAGE_DEFAULT = 20
end
