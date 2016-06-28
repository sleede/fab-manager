class OpenAPI::V1::ReservationsDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Reservations'
    desc 'Reservations made by users'
    formats FORMATS
    api_version API_VERSION
  end

  include OpenAPI::V1::Concerns::ParamGroups

  doc_for :index do
    api :GET, "/#{API_VERSION}/reservations", "Reservations index"
    description "Index of reservations made by users, with optional pagination. Order by *created_at* descendant."
    param_group :pagination
    param :user_id, [Integer, Array], optional: true, desc: "Scope the request to one or various users."
    param :reservable_type, ['Event', 'Machine', 'Training'], optional: true, desc: "Scope the request to a specific type of reservable."
    param :reservable_id, [Integer, Array], optional: true, desc: "Scope the request to one or various reservables."

    example <<-EOS
      # /open_api/v1/reservations?reservable_type=Event&page=1&per_page=3
      {
        "reservations": [
          {
            "id": 3253,
            "user_id": 1744,
            "reservable_id": 162,
            "reservable_type": "Event",
            "updated_at": "2016-05-03T14:14:00.141+02:00",
            "created_at": "2016-05-03T14:14:00.141+02:00",
            "user": {
              "id": 1744,
              "email": "xxxxxxxxxxxx",
              "created_at": "2016-05-03T13:51:03.223+02:00",
              "full_name": "xxxxxxxxxxxx"
            },
            "reservable": {
              "id": 162,
              "title": "INITIATION FAB LAB",
              "description": "A partir de 15 ans : \r\n\r\nDécouvrez le Fab Lab, familiarisez-vous avec les découpeuses laser, les imprimantes 3D, la découpeuse vinyle ... ! Fabriquez un objet simple, à ramener chez vous ! \r\n\r\nAdoptez la Fab Lab attitude !",
              "updated_at": "2016-03-21T15:55:56.306+01:00",
              "created_at": "2016-03-21T15:55:56.306+01:00"
            }
          },
          {
            "id": 3252,
            "user_id": 1514,
            "reservable_id": 137,
            "reservable_type": "Event",
            "updated_at": "2016-05-03T13:54:54.072+02:00",
            "created_at": "2016-05-03T13:54:54.072+02:00",
            "user": {
              "id": 1514,
              "email": "xxxxxxxxxxxx",
              "created_at": "2016-02-24T08:45:09.050+01:00",
              "full_name": "xxxxxxxxxxxx"
            },
            "reservable": {
              "id": 137,
              "title": "INITIATION FAB LAB",
              "description": "A partir de 15 ans : \r\n\r\nDécouvrez le Fab Lab, familiarisez-vous avec les découpeuses laser, les imprimantes 3D, la découpeuse vinyle ... ! Fabriquez un objet simple, à ramener chez vous ! \r\n\r\nAdoptez la Fab Lab attitude !",
              "updated_at": "2016-05-03T13:53:47.172+02:00",
              "created_at": "2016-03-07T15:58:14.113+01:00"
            }
          },
          {
            "id": 3251,
            "user_id": 1743,
            "reservable_id": 162,
            "reservable_type": "Event",
            "updated_at": "2016-05-03T12:28:50.487+02:00",
            "created_at": "2016-05-03T12:28:50.487+02:00",
            "user": {
              "id": 1743,
              "email": "xxxxxxxxxxxx",
              "created_at": "2016-05-03T12:24:38.724+02:00",
              "full_name": "xxxxxxxxxxxx"
            },
            "reservable": {
              "id": 162,
              "title": "INITIATION FAB LAB",
              "description": "A partir de 15 ans : \r\n\r\nDécouvrez le Fab Lab, familiarisez-vous avec les découpeuses laser, les imprimantes 3D, la découpeuse vinyle ... ! Fabriquez un objet simple, à ramener chez vous ! \r\n\r\nAdoptez la Fab Lab attitude !",
              "updated_at": "2016-03-21T15:55:56.306+01:00",
              "created_at": "2016-03-21T15:55:56.306+01:00"
            }
          }
        ]
      }
    EOS
  end
end
