class OpenAPI::V1::BookableMachinesDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Bookable machines'
    desc 'Machines that a given user is allowed to book (allowed to make a reservation)'
    formats FORMATS
    api_version API_VERSION
  end

  doc_for :index do
    api :GET, "/#{API_VERSION}/bookable_machines", "Bookable machines index"
    description "Machines that a given user is allowed to book."
    param :user_id, Integer, required: true, desc: "Id of the given user."
    example <<-EOS
      # /open_api/v1/bookable_machines?user_id=522
      {
        "machines": [
          {
            "id": 3,
            "name": "Shopbot / Grande fraiseuse",
            "slug": "shopbot-grande-fraiseuse",
            "updated_at": "2014-08-19T11:01:12.919+02:00",
            "created_at": "2014-06-30T03:32:31.982+02:00",
            "description": "La fraiseuse numériq ... ",
            "spec": "Surface maximale de travail: 244 ... "
            "hours_remaining": 0
          },
          {
            "id": 5,
            "name": "Petite Fraiseuse",
            "slug": "petite-fraiseuse",
            "updated_at": "2014-06-30T14:33:37.638+02:00",
            "created_at": "2014-06-30T03:32:31.989+02:00",
            "description": "La fraiseuse numérique Roland Modela MDX-20 ... ",
            "spec": "Taille du plateau X/Y : 220 mm x 1 ... "
            "hours_remaining": 0
          },
          {
            "id": 2,
            "name": "Découpeuse vinyle",
            "slug": "decoupeuse-vinyle",
            "updated_at": "2014-06-30T15:10:14.272+02:00",
            "created_at": "2014-06-30T03:32:31.977+02:00",
            "description": "La découpeuse Vinyle, Roland CAMM ...",
            "spec": "Largeurs de support acceptées: de 50 mm à 70 ... 50 cm/sec ... mécanique: 0,0125 mm/pas\r\n",
            "hours_remaining": 0
          },
          {
            "id": 1,
            "name": "Epilog EXT36 Laser",
            "slug": "decoupeuse-laser",
            "updated_at": "2015-02-17T11:06:00.495+01:00",
            "created_at": "2014-06-30T03:32:31.972+02:00",
            "description": "La découpeuse Laser, ... ",
            "spec": "Puissance : 40W Surface de trav ... ",
            "hours_remaining": 0
          },
          {
            "id": 4,
            "name": "Imprimante 3D - Ultimaker",
            "slug": "imprimante-3d",
            "updated_at": "2014-12-11T15:47:02.215+01:00",
            "created_at": "2014-06-30T03:32:31.986+02:00",
            "description": "L'imprimante 3D U ... ",
            "spec": "Surface maximale de travai sés: PLA (en stock).",
            "hours_remaining": 10
          },
          # ...
        ]
      }
    EOS
  end
end
