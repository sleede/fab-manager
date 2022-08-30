# frozen_string_literal: true

# openAPI documentation for plans endpoint
class OpenAPI::V1::PlansDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Plans'
    desc 'Subscription plans of Fab-manager'
    formats FORMATS
    api_version API_VERSION
  end

  doc_for :index do
    api :GET, "/#{API_VERSION}/plans", 'Plans index'
    description 'Plans index. Order by *created_at* ascendant.'
    example <<-PLANS
      # /open_api/v1/plans
      {
        "plans": [
          {
            "id": 1,
            "name": "One month - standard",
            "slug": "one-month-standard",
            "amount": 3000
            "interval": month,
            "interval_count": 1,
            "group_id": 1
            "disabled": null,
            "ui_weight": 3,
            "monthly_payment": false,
            "updated_at": "2001-01-01 15:15:19.860064000 Z",
            "created_at": "2001-01-01 15:19:28.367161000 Z"
          },
          {
            "id": 2,
            "name": "One month - students",
            "slug": "one-month-students",
            "amount": 2000
            "interval": month,
            "interval_count": 1,
            "group_id": 2
            "disabled": null,
            "ui_weight": 0,
            "monthly_payment": false,
            "updated_at": "2016-04-04 15:18:27.734657000 Z",
            "created_at": "2016-04-04 15:18:27.734657000 Z"
          },
          #
          # ....
          #
          {
            "id": 9,
            "name": "One year - corporations",
            "slug": "one-month-corporations",
            "amount": 36000
            "interval": year,
            "interval_count": 1,
            "group_id": 3
            "disabled": null,
            "ui_weight": 9,
            "monthly_payment": true,
            "updated_at": "2020-12-14 14:10:11.056241000 Z",
            "created_at": "2020-12-14 14:10:11.056241000 Z"
          },
        ]
      }
    PLANS
  end

  doc_for :show do
    api :GET, "/#{API_VERSION}/plans/:id", 'Shows a plan'
    description 'Show all details of a single plan.'
    example <<-PLAN
      # /open_api/v1/plans/9
        {
          "id": 9,
          "name": "One year - corporations",
          "slug": "one-month-corporations",
          "amount": 36000
          "interval": year,
          "interval_count": 1,
          "group_id": 3
          "disabled": null,
          "ui_weight": 9,
          "monthly_payment": true,
          "updated_at": "2020-12-14 14:10:11.056241000 Z",
          "created_at": "2020-12-14 14:10:11.056241000 Z",
          "training_credit_nb": 10,
          "is_rolling": true,
          "description": "10 trainings and 30 machine hours offered with your subscription to this plan",
          "type": "Plan",
          "plan_category_id": 2,
          "file": "https://example.com/uploads/plan_file/25/Pricing_Grid_2020_2021_v2.png"
        }
    PLAN
  end
end
