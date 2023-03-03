# frozen_string_literal: true

# openAPI documentation for user endpoint
class OpenAPI::V1::UsersDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Users'
    desc 'Users of Fab-manager'
    formats FORMATS
    api_version API_VERSION
  end

  include OpenAPI::V1::Concerns::ParamGroups

  doc_for :index do
    api :GET, "/#{API_VERSION}/users", 'Users index'
    description 'Users index, paginated. Ordered by *created_at* descendant.'
    param_group :pagination
    param :email, [String, Array], optional: true, desc: 'Filter users by *email* using strict matching.'
    param :user_id, [Integer, Array], optional: true, desc: 'Filter users by *id* using strict matching.'
    param :created_after, DateTime, optional: true, desc: 'Filter users to accounts created after the given date.'
    example <<-USERS
      # /open_api/v1/users?page=1&per_page=4
      {
        "users": [
          {
            "id": 1746,
            "email": "xxxxxxx@xxxx.com",
            "created_at": "2016-05-04T17:21:48.403+02:00",
            "external_id": "J5821-4"
            "full_name": "xxxx xxxx",
            "first_name": "xxxx",
            "last_name": "xxxx",
            "gender": "man",
            "organization": true,
            "address": "2 impasse xxxxxx, BRUXELLES",
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
            "external_id": "J5846-4"
            "full_name": "xxxxx xxxxx",
            "first_name": "xxxxx",
            "last_name": "xxxxx",
            "gender": "woman",
            "organization": true,
            "address": "Grenoble",
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
            "external_id": "J5900-1"
            "full_name": "xxxxxxx xxxx",
            "first_name": "xxxxxxx",
            "last_name": "xxxx",
            "gender": "man",
            "organization": false,
            "address": "21 rue des xxxxxx",
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
            "external_id": "P4172-4"
            "full_name": "xxx xxxxxxx",
            "first_name": "xxx",
            "last_name": "xxxxxxx",
            "gender": "woman",
            "organization": false,
            "address": "147 rue xxxxxx, 75000 PARIS, France",
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
            "external_id": "J5500-4"
            "full_name": "xxxx xxxxxx",
            "first_name": "xxxx",
            "last_name": "xxxxxx",
            "gender": "man",
            "organization": true,
            "address": "38100",
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
            "external_id": null,
            "full_name": "xxxxx xxxxxx",
            "first_name": "xxxx",
            "last_name": "xxxxxx",
            "gender": "woman",
            "organization": true,
            "address": "",
            "group": {
              "id": 2,
              "name": "étudiant, - de 25 ans, enseignant, demandeur d'emploi",
              "slug": "student"
            }
          }
        ]
      }
    USERS
  end
end
