class OpenAPI::V1::EventsDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Events'
    desc 'Events of Fab-manager'
    formats FORMATS
    api_version API_VERSION
  end

  include OpenAPI::V1::Concerns::ParamGroups

  doc_for :index do
    api :GET, "/#{API_VERSION}/events", "Events index"
    param_group :pagination
    description "Events index. Order by *created_at* desc."
    example <<-EOS
      # /open_api/v1/events?page=1&per_page=2
      {
        "events": [
          {
            "id": 183,
            "title": "OPEN LAB",
            "description": "Que vous soyez Fab user, visiteur, curieux ou bricoleur, l’atelier de fabrication numérique vous ouvre ses portes les mercredis soirs pour avancer vos projets ou rencontrer la «communauté» Fab Lab. \r\n\r\nCe soir, venez spécialement découvrir les machines à commandes numérique du Fab Lab de La Casemate, venez comprendre ce lieux ouvert à tous. \r\n\r\n\r\nVenez découvrir un concept, une organisation, des machines, pour stimuler votre sens de la créativité.",
            "updated_at": "2016-04-25T10:49:40.055+02:00",
            "created_at": "2016-04-25T10:49:40.055+02:00",
            "nb_total_places": 18,
            "nb_free_places": 16,
            "prices": {
              "normal": {
                "name": "Plein tarif",
                "amount": 0
              }
            }
          },
          {
            "id": 182,
            "title": "ATELIER SKATE : SEANCE 1",
            "description": "Envie de rider à travers Grenoble sur une planche unique ? Envie de découvrir la fabrication éco-responsable d'un skate ? Alors bienvenue à l'atelier Skate Board du Fablab ! Encadré par Ivan Mago et l'équipe du FabLab, vous réaliserez votre planche (skate, longboard,...) depuis son design jusqu'à sa décoration sur 4 séances.\r\n\r\nLe tarif 50€ inclut  la participation aux ateliers, l'utilisations des machines, et tout le matériel de fabrication (bois+colle+grip+vinyle).\r\n\r\nCette première séance sera consacré au design de votre planche et à la découpe des gabarits. N'hésitez pas à venir avec votre ordinateur et vos logiciels de création 2D si vous le souhaitez.\r\n\r\nNous vous attendons nombreux !",
            "updated_at": "2016-04-11T17:40:15.146+02:00",
            "created_at": "2016-04-11T17:40:15.146+02:00",
            "nb_total_places": 8,
            "nb_free_places": 0,
            "prices": {
              "normal": {
                "name": "Plein tarif",
                "amount": 5000
              },
              "1": {
                "name": "Tarif réduit",
                "amount": 4000
              },
            }
          }
        ]
      }
    EOS
  end
end
