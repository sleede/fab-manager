# frozen_string_literal: true

# openAPI documentation for invoices endpoints
class OpenAPI::V1::InvoicesDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Invoices'
    desc 'Invoices'
    formats FORMATS
    api_version API_VERSION
  end

  include OpenAPI::V1::Concerns::ParamGroups

  doc_for :index do
    api :GET, "/#{API_VERSION}/invoices", 'Invoices index'
    description 'Index of invoices, paginated. Ordered by *created_at* descendant.'
    param_group :pagination
    param :user_id, [Integer, Array], optional: true, desc: 'Scope the request to one or various users.'
    example <<-INVOICES
      # /open_api/v1/invoices?user_id=211&page=1&per_page=3
      {
        "invoices": [
          {
            "id": 2809,
            "user_id": 211,
            "payment_gateway_object": {
              id: "in_187DLE4zBvgjueAZ6L7SyQlU",
              type: "Stripe::Invoice"
            },
            "reference": "1605017/VL",
            "total": 1000,
            "type": null,
            "description": null,
            "invoice_url": "/open_api/v1/invoices/2809/download",
            "main_object": {
              "type": "Reservation",
              "id": 3257,
              "created_at": "2016-05-04T01:54:16.686+02:00"
            }
          },
          {
            "id": 2783,
            "user_id": 211,
            "payment_gateway_object": {
              id: "pi_2Dat4P2eYbKYlo2C3MxszwQp",
              type: "Stripe::PaymentIntent"
            },
            "reference": "1604176/VL",
            "total": 2000,
            "type": null,
            "description": null,
            "invoice_url": "/open_api/v1/invoices/2783/download",
            "main_object": {
              "type": "Reservation",
              "id": 3229,
              "created_at": "2016-04-28T18:14:52.524+02:00"
            }
          },
          {
            "id": 2773,
            "user_id": 211,
            "payment_gateway_object": {
              id: "ba15dc9d8f3e0fa17bf527466",
              type: "PayZen::Order"
            },
            "reference": "1604166/VL",
            "total": 2000,
            "type": null,
            "description": null,
            "invoice_url": "/open_api/v1/invoices/2773/download",
            "main_object": {
              "type": "Reservation",
              "id": 3218,
              "created_at": "2016-04-27T10:50:30.806+02:00"
            }
          }
        ]
      }
    INVOICES
  end

  doc_for :download do
    api :GET, "/#{API_VERSION}/invoices/:id/download", 'Download an invoice'
    param :id, Integer, desc: 'Invoice id', required: true

    example <<-URL
      # /open_api/v1/invoices/2809/download
    URL
  end
end
