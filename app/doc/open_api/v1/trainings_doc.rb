class OpenAPI::V1::TrainingsDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Trainings'
    desc 'Trainings of Fab-manager'
    formats FORMATS
    api_version API_VERSION
  end

  doc_for :index do
    api :GET, "/#{API_VERSION}/trainings", "Trainings index"
    description "Trainings index. Order by *created_at* ascendant."
    example <<-EOS
      # /open_api/v1/trainings
      {
        "trainings": [
          {
            "id": 1,
            "name": "Formation Imprimante 3D",
            "slug": "formation-imprimante-3d",
            "updated_at": "2015-02-05T13:49:15.025+01:00",
            "created_at": "2014-06-30T03:32:32.126+02:00",
            "nb_total_places": 8,
            "description": null
          },
          {
            "id": 2,
            "name": "Formation Laser / Vinyle",
            "slug": "formation-laser-vinyle",
            "updated_at": "2015-02-05T13:49:19.046+01:00",
            "created_at": "2014-06-30T03:32:32.138+02:00",
            "nb_total_places": 8,
            "description": null
          },
          {
            "id": 3,
            "name": "Formation Petite fraiseuse numerique",
            "slug": "formation-petite-fraiseuse-numerique",
            "updated_at": "2015-02-05T13:49:23.040+01:00",
            "created_at": "2014-06-30T03:32:32.164+02:00",
            "nb_total_places": 8,
            "description": null
          },
          {
            "id": 4,
            "name": "Formation Shopbot Grande Fraiseuse",
            "slug": "formation-shopbot-grande-fraiseuse",
            "updated_at": "2015-02-03T10:22:21.908+01:00",
            "created_at": "2014-06-30T03:32:32.168+02:00",
            "nb_total_places": 6,
            "description": null
          },
          {
            "id": 5,
            "name": "Formation logiciel 2D",
            "slug": "formation-logiciel-2d",
            "updated_at": "2015-02-05T13:49:27.460+01:00",
            "created_at": "2014-06-30T09:37:42.778+02:00",
            "nb_total_places": 8,
            "description": null
          },
          {
            "id": 6,
            "name": "Pas de Reservation",
            "slug": "pas-de-reservation",
            "updated_at": "2014-07-22T14:18:11.784+02:00",
            "created_at": "2014-07-22T14:18:11.784+02:00",
            "nb_total_places": null,
            "description": null
          }
        ]
      }
    EOS
  end
end
