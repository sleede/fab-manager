class OpenAPI::V1::BaseDoc < OpenAPI::ApplicationDoc
  API_VERSION = "v1"
  FORMATS = ['json']
  PER_PAGE_DEFAULT = 20
end
