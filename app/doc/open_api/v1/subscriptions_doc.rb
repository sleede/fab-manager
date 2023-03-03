# frozen_string_literal: true

# openAPI documentation for subscriptions endpoints
class OpenAPI::V1::SubscriptionsDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Subscriptions'
    desc 'Subscriptions'
    formats FORMATS
    api_version API_VERSION
  end

  include OpenAPI::V1::Concerns::ParamGroups

  doc_for :index do
    api :GET, "/#{API_VERSION}/subscriptions", 'Subscriptions index'
    description "Index of users' subscriptions, paginated. Order by *created_at* descendant."
    param_group :pagination
    param :user_id, [Integer, Array], optional: true, desc: 'Scope the request to one or various users.'
    param :plan_id, [Integer, Array], optional: true, desc: 'Scope the request to one or various plans.'
    example <<-SUBSCRIPTIONS
      # /open_api/v1/subscriptions?user_id=211&page=1&per_page=3
      {
        "subscriptions": [
          {
            "id": 2809,
            "user_id": 211,
            "created_at": "2022-08-26T09:41:02.426+02:00",
            "expiration_date": "2022-09-26T09:41:02.427+02:00",
            "canceled_at": null,
            "plan_id": 1
          },
          {
            "id": 2783,
            "user_id": 211,
            "created_at": "2022-06-06T20:03:33.470+02:00",
            "expiration_date": "2022-07-06T20:03:33.470+02:00",
            "canceled_at": null,
            "plan_id": 1
          },
          {
            "id": 2773,
            "user_id": 211,
            "created_at": "2021-12-23T19:26:36.852+01:00",
            "expiration_date": "2022-01-23T19:26:36.852+01:00",
            "canceled_at": null,
            "plan_id": 1
          }
        ]
      }
    SUBSCRIPTIONS
  end
end
