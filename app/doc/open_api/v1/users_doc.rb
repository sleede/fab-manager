class OpenAPI::V1::UsersDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Users'
    desc 'Users of Fab-manager'
    formats FORMATS
    api_version API_VERSION
  end

  include OpenAPI::V1::Concerns::ParamGroups

  doc_for :index do
    api :GET, "/#{API_VERSION}/users", "Users index"
    description "Users index, with optional pagination. Order by *created_at* descendant."
    param_group :pagination
    param :email, [String, Array], optional: true, desc: "Filter users by *email* using strict matching."
    param :user_id, [Integer, Array], optional: true, desc: "Filter users by *id* using strict matching."
    example <<-EOS
      # /open_api/v1/users?page=1&per_page=4
      {
        "users": [
          {
            "id": 1746,
            "email": "xxxxxxx@xxxx.com",
            "created_at": "2016-05-04T17:21:48.403+02:00",
            "full_name": "xxxx xxxx",
            "group": {
              "id": 1,
              "name": "standard, association",
              "slug": "standard"
            }
          },
          {
            "id": 1745,
            "email": "xxxxxxx@gmail.com",
            "created_at": "2016-05-03T15:21:13.125+02:00",
            "full_name": "xxxxx xxxxx",
            "group": {
              "id": 2,
              "name": "étudiant, - de 25 ans, enseignant, demandeur d'emploi",
              "slug": "student"
            }
          },
          {
            "id": 1744,
            "email": "xxxxxxx@gmail.com",
            "created_at": "2016-05-03T13:51:03.223+02:00",
            "full_name": "xxxxxxx xxxx",
            "group": {
              "id": 1,
              "name": "standard, association",
              "slug": "standard"
            }
          },
          {
            "id": 1743,
            "email": "xxxxxxxx@setecastronomy.eu",
            "created_at": "2016-05-03T12:24:38.724+02:00",
            "full_name": "xxx xxxxxxx",
            "group": {
              "id": 1,
              "name": "standard, association",
              "slug": "standard"
            }
          }
        ]
      }

      # /open_api/v1/users?user_id[]=1746&user_id[]=1745
      {
        "users": [
          {
            "id": 1746,
            "email": "xxxxxxxxxxxx",
            "created_at": "2016-05-04T17:21:48.403+02:00",
            "full_name": "xxxx xxxxxx",
            "group": {
              "id": 1,
              "name": "standard, association",
              "slug": "standard"
            }
          },
          {
            "id": 1745,
            "email": "xxxxxxxxx@gmail.com",
            "created_at": "2016-05-03T15:21:13.125+02:00",
            "full_name": "xxxxx xxxxxx",
            "group": {
              "id": 2,
              "name": "étudiant, - de 25 ans, enseignant, demandeur d'emploi",
              "slug": "student"
            }
          }
        ]
      }
    EOS
  end
end
