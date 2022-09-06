# frozen_string_literal: true

# openAPI documentation for prices endpoint
class OpenAPI::V1::PricesDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Prices'
    desc 'Prices for all resources'
    formats FORMATS
    api_version API_VERSION
  end

  include OpenAPI::V1::Concerns::ParamGroups

  doc_for :index do
    api :GET, "/#{API_VERSION}/prices", 'Prices index'
    description 'Index of prices, with optional pagination. Order by *created_at* descendant.'
    param_group :pagination
    param :plan_id, [Integer, Array, 'null'], optional: true, desc: 'Scope the request to one or various plans. Provide "null" to ' \
                                                                    'this parameter to get prices not associated with any plans (prices ' \
                                                                    'that applies to users without subscriptions).'
    param :group_id, [Integer, Array], optional: true, desc: 'Scope the request to one or various groups.'
    param :priceable_type, %w[Machine Space], optional: true, desc: 'Scope the request to a specific type of resource.'
    param :priceable_id, [Integer, Array], optional: true, desc: 'Scope the request to one or various resources.'

    example <<-PRICES
      # /open_api/v1/prices?priceable_type=Space&page=1&per_page=3
      {
        "prices": [
          {
            "id": 502,
            "priceable_id": 1,
            "priceable_type": "Space",
            "group_id": 4,
            "plan_id": 5,
            "amount": 1800,
            "updated_at": "2021-06-21T09:40:40.467277+01:00",
            "created_at": "2021-06-21T09:40:40.467277+01:00",
          },
          {
            "id": 503,
            "priceable_id": 1,
            "priceable_type": "Space",
            "group_id": 2,
            "plan_id": 1,
            "amount": 1600,
            "updated_at": "2021-06-21T09:40:40.470904+01:00",
            "created_at": "2021-06-21T09:40:40.470904+01:00",
          },
          {
            "id": 504,
            "priceable_id": 1,
            "priceable_type": "Space",
            "group_id": 3,
            "plan_id": 3,
            "amount": 2000,
            "updated_at": "2021-06-21T09:40:40.470876+01:00",
            "created_at": "2021-06-21T09:40:40.470876+01:00",
          }
        ]
      }
    PRICES
  end
end
