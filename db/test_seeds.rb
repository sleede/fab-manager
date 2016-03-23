Group.create!([
  {name: "standard, association", slug: "standard"},
  {name: "étudiant, - de 25 ans, enseignant, demandeur d'emploi", slug: "student"},
  {name: "artisan, commerçant, chercheur, auto-entrepreneur", slug: "merchant"},
  {name: "PME, PMI, SARL, SA", slug: "business"}
])

if Category.count == 0
  Category.create!([
    {name: "Stage"},
    {name: "Atelier"}
  ])
end

if StatisticIndex.count == 0
  StatisticIndex.create!([
    {id:1, es_type_key:'subscription', label:'Abonnements'},
    {id:2, es_type_key:'machine', label:'Heures machines'},
    {id:3, es_type_key:'training', label:'Formations'},
    {id:4, es_type_key:'event', label:'Ateliers/Stages'},
    {id:5, es_type_key:'account', label:'Inscriptions', ca: false},
    {id:6, es_type_key:'project', label:'Projets', ca: false},
    {id:7, es_type_key:'user', label:'Utilisateurs', table: false, ca: false}
  ])
  connection = ActiveRecord::Base.connection
  if connection.instance_values["config"][:adapter] == 'postgresql'
    connection.execute("SELECT setval('statistic_indices_id_seq', 7);")
  end
end

if StatisticField.count == 0
  StatisticField.create!([
    # available data_types : index, number, date, text, list
    {key:'trainingId', label:'ID Formation', statistic_index_id: 3, data_type: 'index'},
    {key:'trainingDate', label:'Date Formation', statistic_index_id: 3, data_type: 'date'},
    {key:'eventId', label:'ID Évènement', statistic_index_id: 4, data_type: 'index'},
    {key:'eventDate', label:'Date Évènement', statistic_index_id: 4, data_type: 'date'},
    {key:'themes', label:'Thèmes', statistic_index_id: 6, data_type: 'list'},
    {key:'components', label:'Composants', statistic_index_id: 6, data_type: 'list'},
    {key:'machines', label:'Machines', statistic_index_id: 6, data_type: 'list'},
    {key:'name', label:'Nom Évènement', statistic_index_id: 4, data_type: 'text'},
    {key:'userId', label:'ID Utilisateur', statistic_index_id: 7, data_type: 'index'}
  ])
end

if StatisticType.count == 0
  StatisticType.create!([
    {id:1, statistic_index_id: 1, key: 'month', label:'Abonnements mensuels', graph: true, simple: true},
    {id:2, statistic_index_id: 1, key: 'year', label:'Abonnements annuels', graph: true, simple: true},
    {id:3, statistic_index_id: 2, key: 'booking', label:'Réservations', graph: true, simple: true},
    {id:4, statistic_index_id: 2, key: 'hour', label:"Nombre d'heures", graph: true, simple: false},
    {id:5, statistic_index_id: 3, key: 'booking', label:'Réservations', graph: false, simple: true},
    {id:6, statistic_index_id: 3, key: 'hour', label:"Nombre d'heures", graph: false, simple: false},
    {id:7, statistic_index_id: 4, key: 'booking', label:'Nombre de places', graph: false, simple: false},
    {id:8, statistic_index_id: 4, key: 'hour', label:"Nombre d'heures", graph: false, simple: false},
    {id:9, statistic_index_id: 5, key: 'member', label:'Utilisateurs', graph: true, simple: true},
    {id:10, statistic_index_id: 6, key: 'project', label:'Projets', graph: false, simple: true},
    {id:11, statistic_index_id: 7, key: 'revenue', label:"Chiffre d'affaires", graph: false, simple: false}
  ])
  connection = ActiveRecord::Base.connection
  if connection.instance_values["config"][:adapter] == 'postgresql'
    connection.execute("SELECT setval('statistic_types_id_seq', 11);")
  end
end
