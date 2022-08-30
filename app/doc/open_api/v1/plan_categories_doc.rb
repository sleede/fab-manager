# frozen_string_literal: true

# openAPI documentation for plan categories endpoint
class OpenAPI::V1::PlanCategoriesDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Plans categories'
    desc 'Categories of subscription plans'
    formats FORMATS
    api_version API_VERSION
  end

  doc_for :index do
    api :GET, "/#{API_VERSION}/plan_categories", 'Plans categories index'
    description 'Plans categories index. Order by *created_at* ascendant.'
    example <<-PLAN_CATEGORIES
      # /open_api/v1/plan_categories
      {
        "plan_categories": [
          {
            "id": 1,
            "name": "CRAZY LAB",
            "weight": 0,
            "description": "Lorem ipsum dolor sit amet",
            "updated_at": "2021-12-01 15:15:19.860064000 Z",
            "created_at": "2021-12-01 15:19:28.367161000 Z"
          },
          {
            "id": 2,
            "name": "PREMIUM",
            "weight": 1,
            "description": "<p>Lorem ipsum <b>dolor</b> sit amet</p>",
            "updated_at": "2021-12-01 15:15:19.860064000 Z",
            "created_at": "2021-12-01 15:19:28.367161000 Z"
          }
        ]
      }
    PLAN_CATEGORIES
  end
end
