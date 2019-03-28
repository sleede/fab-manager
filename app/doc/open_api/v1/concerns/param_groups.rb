# frozen_string_literal: true

# openAPI pagination
module OpenAPI::V1::Concerns::ParamGroups
  extend ActiveSupport::Concern

  included do
    define_param_group :pagination do
      param :page, Integer, desc: 'Page number', optional: true
      param :per_page, Integer, desc: "Number of objects per page. Default is #{OpenAPI::V1::BaseDoc::PER_PAGE_DEFAULT}.", optional: true
    end
  end
end
