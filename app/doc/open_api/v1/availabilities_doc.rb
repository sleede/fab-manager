# frozen_string_literal: true

# openAPI documentation for reservations endpoint
class OpenAPI::V1::AvailabilitiesDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Availabilities'
    desc 'Slots availables for reservation'
    formats FORMATS
    api_version API_VERSION
  end

  include OpenAPI::V1::Concerns::ParamGroups

  doc_for :index do
    api :GET, "/#{API_VERSION}/availabilities", 'Availabilities index'
    description 'Index of reservable availabilities and their slots, paginated. Ordered by *start_at* descendant.'
    param_group :pagination
    param :after, DateTime, optional: true, desc: 'Filter availabilities to those starting after the given date.'
    param :before, DateTime, optional: true, desc: 'Filter availabilities to those ending before the given date.'
    param :user_id, [Integer, Array], optional: true, desc: 'Scope the request to one or various users.'
    param :available_type, %w[Event Machine Space Training], optional: true, desc: 'Scope the request to a specific type of reservable.'
    param :available_id, [Integer, Array], optional: true, desc: 'Scope the request to one or various reservables. <br>' \
                                                                 '<b>WARNING</b>: filtering by <i>available_id</i> is only available if ' \
                                                                 'filter <i>available_type</i> is provided'

    example <<-AVAILABILITIES
      # /open_api/v1/availabilities?available_type=Machine&page=1&per_page=3
      {
        "availabilities": [
          {
              "id": 5115,
              "start_at": "2023-07-13T14:00:00.000+02:00",
              "end_at": "2023-07-13T18:00:00.000+02:00",
              "created_at": "2023-01-24T12:28:25.905+01:00",
              "available_type": "Machine",
              "available_ids": [
                  5,
                  9,
                  10,
                  15,
                  8,
                  12,
                  17,
                  16,
                  3,
                  2,
                  14,
                  18
              ],
              "slots": [
                  {
                      "id": 17792,
                      "start_at": "2023-07-13T14:00:00.000+02:00",
                      "end_at": "2023-07-13T15:00:00.000+02:00"
                  },
                  {
                      "id": 17793,
                      "start_at": "2023-07-13T15:00:00.000+02:00",
                      "end_at": "2023-07-13T16:00:00.000+02:00"
                  },
                  {
                      "id": 17794,
                      "start_at": "2023-07-13T16:00:00.000+02:00",
                      "end_at": "2023-07-13T17:00:00.000+02:00"
                  },
                  {
                      "id": 17795,
                      "start_at": "2023-07-13T17:00:00.000+02:00",
                      "end_at": "2023-07-13T18:00:00.000+02:00"
                  }
              ]
          },
          {
              "id": 5112,
              "start_at": "2023-07-07T14:00:00.000+02:00",
              "end_at": "2023-07-07T18:00:00.000+02:00",
              "created_at": "2023-01-24T12:26:45.997+01:00",
              "available_type": "Machine",
              "available_ids": [
                  5,
                  9,
                  10,
                  15,
                  8,
                  12,
                  17,
                  16,
                  3,
                  2,
                  14,
                  18
              ],
              "slots": [
                  {
                      "id": 17786,
                      "start_at": "2023-07-07T14:00:00.000+02:00",
                      "end_at": "2023-07-07T15:00:00.000+02:00"
                  },
                  {
                      "id": 17787,
                      "start_at": "2023-07-07T15:00:00.000+02:00",
                      "end_at": "2023-07-07T16:00:00.000+02:00"
                  },
                  {
                      "id": 17788,
                      "start_at": "2023-07-07T16:00:00.000+02:00",
                      "end_at": "2023-07-07T17:00:00.000+02:00"
                  },
                  {
                      "id": 17789,
                      "start_at": "2023-07-07T17:00:00.000+02:00",
                      "end_at": "2023-07-07T18:00:00.000+02:00"
                  }
              ]
          },
          {
              "id": 5111,
              "start_at": "2023-07-06T14:00:00.000+02:00",
              "end_at": "2023-07-06T18:00:00.000+02:00",
              "created_at": "2023-01-24T12:26:37.189+01:00",
              "available_type": "Machine",
              "available_ids": [
                  5,
                  9,
                  10,
                  15,
                  8,
                  12,
                  17,
                  16,
                  3,
                  2,
                  14,
                  18
              ],
              "slots": [
                  {
                      "id": 17782,
                      "start_at": "2023-07-06T14:00:00.000+02:00",
                      "end_at": "2023-07-06T15:00:00.000+02:00"
                  },
                  {
                      "id": 17783,
                      "start_at": "2023-07-06T15:00:00.000+02:00",
                      "end_at": "2023-07-06T16:00:00.000+02:00"
                  },
                  {
                      "id": 17784,
                      "start_at": "2023-07-06T16:00:00.000+02:00",
                      "end_at": "2023-07-06T17:00:00.000+02:00"
                  },
                  {
                      "id": 17785,
                      "start_at": "2023-07-06T17:00:00.000+02:00",
                      "end_at": "2023-07-06T18:00:00.000+02:00"
                  }
              ]
          }
      ]
      }
    AVAILABILITIES
  end
end
