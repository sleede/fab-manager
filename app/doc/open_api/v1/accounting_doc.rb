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
    description 'All accounting lines, paginated (necessarily becauce there is a lot of data) with optional dates filtering. ' \
                'Ordered by *date* descendant.<br>' \
                'The field *status* indicates if the accounting data is being built or if the build is over. ' \
                'Possible status are: <i>building</i> or <i>built</i>.<br>' \
                'The field *invoice.payment_details* is available if line_type=client. It will contain the following data:<br>' \
                '· *payment_mean*, possible status are: <i>card</i>, <i>wallet</i> or <i>other</i>. *WARNING*: If an invoice was settled ' \
                'using multiple payment means, this will only report the payment mean applicable to current line.<br>' \
                '· *gateway_object_id*, if payment_mean=card, report the ID of the payment gateway related object<br>' \
                '· *gateway_object_type*, if payment_mean=card, report the type of the payment gateway related object<br>' \
                '· *wallet_transaction_id*, if payment_mean=wallet, report the ID of the wallet transaction<br>'
    param_group :pagination
    param :after, DateTime, optional: true, desc: 'Filter accounting lines to lines after the given date.'
    param :before, DateTime, optional: true, desc: 'Filter accounting lines to lines before the given date.'
    param :invoice_id, [Integer, Array], optional: true, desc: 'Scope the request to one or various invoices.'
    param :type, %w[client vat item], optional: true, desc: 'Filter accounting lines by line type.'

    example <<-LINES
      # /open_api/v1/accounting?after=2022-01-01T00:00:00+02:00&page=1&per_page=3
      {
        "lines": [
          {
            "id": 1,
            "line_type": "client",
            "journal_code": "VT01",
            "date": "2022-01-02T18:14:21+01:00",
            "account_code": "5802",
            "account_label": "Card customers",
            "analytical_code": "",
            "invoice": {
              "reference": "22010009/VL",
              "id": 274,
              "label": "Subscription of Dupont Marcel for 1 month starting from 2022, january 2nd",
              "url": "/open_api/v1/invoices/247/download",
              "payment_details": {
                "payment_mean": "card",
                "gateway_object_id": "pi_3MA2PPW4kx8QemzC02ABBEbo",
                "gateway_object_type": "Stripe::PaymentIntent"
              }
            },
            "user": {
              "invoicing_profile_id": 6512,
              "external_id": "U52-ALC4"
            },
            "debit": 1400,
            "credit": 0
            "currency": "EUR",
            "summary": "Dupont Marcel, 22010009/VL, subscr."
          },
          {
            "id": 2,
            "line_type": "item",
            "journal_code": "VT01",
            "date": "2022-01-02T18:14:21+01:00",
            "account_code": "7071",
            "account_label": "Subscriptions",
            "analytical_code": "P3D71",
            "invoice": {
              "reference": "22010009/VL",
              "id": 274,
              "label": "Subscription of Dupont Marcel for 1 month starting from 2022, january 2nd",
              "url": "/open_api/v1/invoices/247/download"
            },
            "user_invoicing_profile_id": 6512,
            "debit": 0,
            "credit": 1167
            "currency": "EUR",
            "summary": "Dupont Marcel, 22010009/VL, subscr."
          },
          {
            "id": 3,
            "line_type": "vat",
            "journal_code": "VT01",
            "date": "2022-01-02T18:14:21+01:00",
            "account_code": "4457",
            "account_label": "Collected VAT",
            "analytical_code": "P3D71",
            "invoice": {
              "reference": "22010009/VL",
              "id": 274,
              "label": "Subscription of Dupont Marcel for 1 month starting from 2022, january 2nd",
              "url": "/open_api/v1/invoices/247/download"
            },
            "user_invoicing_profile_id": 6512,
            "debit": 0,
            "credit": 233
            "currency": "EUR",
            "summary": "Dupont Marcel, 22010009/VL, subscr."
          }
        ],
        "status": "built"
      }
    LINES
  end
end
