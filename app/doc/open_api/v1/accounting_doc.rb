# frozen_string_literal: true

# openAPI documentation for accounting endpoints
class OpenAPI::V1::AccountingDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Accounting lines'
    desc 'Accounting lines according to the French General Accounting Plan (PCG)'
    formats FORMATS
    api_version API_VERSION
  end

  include OpenAPI::V1::Concerns::ParamGroups

  doc_for :index do
    api :GET, "/#{API_VERSION}/accounting", 'Accounting lines'
    description 'All accounting lines, with optional pagination and dates filtering. Ordered by *date* descendant.'
    param_group :pagination
    param :after, DateTime, optional: true, desc: 'Filter accounting lines to lines after the given date.'
    param :before, DateTime, optional: true, desc: 'Filter accounting lines to lines before the given date.'
    example <<-LINES
      # /open_api/v1/accounting?after=2022-01-01T00:00:00+02:00&page=1&per_page=3
      {
        "lines": [
          {
            "journal_code": "VT01",
            "date": "2022-01-02T18:14:21+01:00",
            "account_code": "5802",
            "account_label": "Wallet customers",
            "analytical_code": "P3D71",
            "invoice": {
              "reference": "22010009/VL",
              "id": 274,
              "label": "Dupont Marcel, 22010009/VL, subscr.",
            },
            "user_id": 6512,
            "amount": 200,
            "currency": "EUR",
            "invoice_url": "/open_api/v1/invoices/247/download"
          },
          {
            "journal_code": "VT01",
            "date": "2022-01-02T18:14:21+01:00",
            "account_code": "5801",
            "account_label": "Card customers",
            "analytical_code": "P3D71",
            "invoice": {
              "reference": "22010009/VL",
              "id": 274,
              "label": "Dupont Marcel, 22010009/VL, subscr.",
            },
            "user_id": 6512,
            "amount": 100,
            "currency": "EUR",
            "invoice_url": "/open_api/v1/invoices/247/download"
          },
          {
            "journal_code": "VT01",
            "date": "2022-01-02T18:14:21+01:00",
            "account_code": "5802",
            "account_label": "Wallet customers",
            "analytical_code": "P3D71",
            "invoice": {
              "reference": "22010009/VL",
              "id": 274,
              "label": "Dupont Marcel, 22010009/VL, subscr.",
            },
            "user_id": 6512,
            "amount": 200,
            "currency": "EUR",
            "invoice_url": "/open_api/v1/invoices/247/download"
          }
        ]
      }
    LINES
  end
end
