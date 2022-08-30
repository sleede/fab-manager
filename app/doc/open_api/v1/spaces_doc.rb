# frozen_string_literal: true

# openAPI documentation for spaces endpoint
class OpenAPI::V1::SpacesDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Spaces'
    desc 'Spaces of Fab-manager'
    formats FORMATS
    api_version API_VERSION
  end

  doc_for :index do
    api :GET, "/#{API_VERSION}/spaces", 'Spaces index'
    description 'Spaces index. Order by *created_at* ascendant.'
    example <<-SPACES
      # /open_api/v1/spaces
      {
        "spaces": [
          {
            "id": 1,
            "name": "Wood workshop",
            "slug": "wood-workshop",
            "disabled": null,
            "updated_at": "2017-02-15 15:55:04.123928000 Z",
            "created_at": "2017-02-24 18:02:21.852147000+01:00",
            "description": "Become a real carpenter in the wood workshop area of your fablab.\r\n",
            "characteristics": "Tools available: Coping saw, plane, jointer, beveller and pyrographer.\r\n"
          },
          {
            "id": 2,
            "name": "Movie studio",
            "slug": "Movie-studio",
            "disabled": null,
            "updated_at": "2018-04-22 18:16:09.143617000 Z",
            "created_at": "2018-06-29T07:47:59.187510000+02:00",
            "description": "Think of yourself as Alfred Hitchcock and let your imagination run free to take your best indoor shots in this fully-equipped cinema studio.\r\n",
            "spec": "Thanks to a system of hanging curtains, this studio is divisible into 3 parts of 90m², each one being equipped with a fixed grill of 9Mx7M, an inlay green screen of 8.5Mx8M opening, as well as 8 projectors DMX controlled cycloids for green screen lighting."
          }
        ]
      }
    SPACES
  end

  doc_for :show do
    api :GET, "/#{API_VERSION}/spaces/:id", 'Show a space'
    description 'Show all the details of single space.'
    example <<-SPACES
      # /open_api/v1/spaces/1
        {
          "id": 1,
          "name": "Wood workshop",
          "slug": "wood-workshop",
          "disabled": null,
          "updated_at": "2017-02-15 15:55:04.123928000 Z",
          "created_at": "2017-02-24 18:02:21.852147000+01:00",
          "description": "Become a real carpenter in the wood workshop area of your fablab.\r\n",
          "characteristics": "Tools available: Coping saw, plane, jointer, beveller and pyrographer.\r\n",
          "default_places": 4,
          "image": "https://example.com/uploads/space_image/2686/space_image.jpg"
        }
    SPACES
  end
end
