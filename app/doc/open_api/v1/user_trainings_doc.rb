class OpenAPI::V1::UserTrainingsDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'User trainings'
    desc 'Trainings validated by users'
    formats FORMATS
    api_version API_VERSION
  end

  include OpenAPI::V1::Concerns::ParamGroups

  doc_for :index do
    api :GET, "/#{API_VERSION}/user_trainings", "User trainings index"
    description "Index of trainings accomplished by users, with optional pagination. Order by *created_at* descendant."
    param_group :pagination
    param :training_id, [Integer, Array], optional: true, desc: "Scope the request to one or various trainings."
    param :user_id, [Integer, Array], optional: true, desc: "Scope the request to one or various users."
    example <<-EOS
      # /open_api/v1/user_trainings?training_id[]=3&training_id[]=4&page=1&per_page=2
      {
        "user_trainings": [
          {
            "id": 720,
            "user_id": 1340,
            "training_id": 3,
            "updated_at": "2016-05-03T14:16:38.373+02:00",
            "created_at": "2016-05-03T14:16:38.373+02:00",
            "user": {
              "id": 1340,
              "email": "xxxxxxxxxxx",
              "created_at": "2015-12-20T11:30:32.670+01:00",
              "full_name": "xxxxxxxxxxx"
            }
          },
          {
            "id": 719,
            "user_id": 1118,
            "training_id": 4,
            "updated_at": "2016-04-29T16:55:24.651+02:00",
            "created_at": "2016-04-29T16:55:24.651+02:00",
            "user": {
              "id": 1118,
              "email": "xxxxxxxxxxx",
              "created_at": "2015-10-08T19:18:26.188+02:00",
              "full_name": "xxxxxxxxxxx"
            }
          }
        ]
      }

      # /open_api/v1/user_trainings?user_id=1340&page=1&per_page=3
      {
        "user_trainings": [
          {
            "id": 720,
            "user_id": 1340,
            "training_id": 3,
            "updated_at": "2016-05-03T14:16:38.373+02:00",
            "created_at": "2016-05-03T14:16:38.373+02:00",
            "training": {
              "id": 3,
              "name": "Formation Petite fraiseuse numerique",
              "slug": "formation-petite-fraiseuse-numerique",
              "updated_at": "2015-02-05T13:49:23.040+01:00",
              "created_at": "2014-06-30T03:32:32.164+02:00"
            }
          },
          {
            "id": 700,
            "user_id": 1340,
            "training_id": 2,
            "updated_at": "2016-04-19T22:02:17.083+02:00",
            "created_at": "2016-04-19T22:02:17.083+02:00",
            "training": {
              "id": 2,
              "name": "Formation Laser / Vinyle",
              "slug": "formation-laser-vinyle",
              "updated_at": "2015-02-05T13:49:19.046+01:00",
              "created_at": "2014-06-30T03:32:32.138+02:00"
            }
          },
          {
            "id": 694,
            "user_id": 1340,
            "training_id": 1,
            "updated_at": "2016-04-13T09:22:49.633+02:00",
            "created_at": "2016-04-13T09:22:49.633+02:00",
            "training": {
              "id": 1,
              "name": "Formation Imprimante 3D",
              "slug": "formation-imprimante-3d",
              "updated_at": "2015-02-05T13:49:15.025+01:00",
              "created_at": "2014-06-30T03:32:32.126+02:00"
            }
          }
        ]
      }
    EOS
  end
end
