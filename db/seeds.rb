# frozen_string_literal: true

if StatisticIndex.count.zero?
  StatisticIndex.create!([
                           { id: 1, es_type_key: 'subscription', label: I18n.t('statistics.subscriptions') },
                           { id: 2, es_type_key: 'machine', label: I18n.t('statistics.machines_hours') },
                           { id: 3, es_type_key: 'training', label: I18n.t('statistics.trainings') },
                           { id: 4, es_type_key: 'event', label: I18n.t('statistics.events') },
                           { id: 5, es_type_key: 'account', label: I18n.t('statistics.registrations'), ca: false },
                           { id: 6, es_type_key: 'project', label: I18n.t('statistics.projects'), ca: false },
                           { id: 7, es_type_key: 'user', label: I18n.t('statistics.users'), table: false, ca: false }
                         ])
  connection = ActiveRecord::Base.connection
  connection.execute("SELECT setval('statistic_indices_id_seq', 7);") if connection.instance_values['config'][:adapter] == 'postgresql'
end

if StatisticField.count.zero?
  StatisticField.create!([
                           # available data_types : index, number, date, text, list
                           { key: 'trainingId', label: I18n.t('statistics.training_id'), statistic_index_id: 3, data_type: 'index' },
                           { key: 'trainingDate', label: I18n.t('statistics.training_date'), statistic_index_id: 3, data_type: 'date' },
                           { key: 'eventId', label: I18n.t('statistics.event_id'), statistic_index_id: 4, data_type: 'index' },
                           { key: 'eventDate', label: I18n.t('statistics.event_date'), statistic_index_id: 4, data_type: 'date' },
                           { key: 'themes', label: I18n.t('statistics.themes'), statistic_index_id: 6, data_type: 'list' },
                           { key: 'components', label: I18n.t('statistics.components'), statistic_index_id: 6, data_type: 'list' },
                           { key: 'machines', label: I18n.t('statistics.machines'), statistic_index_id: 6, data_type: 'list' },
                           { key: 'name', label: I18n.t('statistics.event_name'), statistic_index_id: 4, data_type: 'text' },
                           { key: 'userId', label: I18n.t('statistics.user_id'), statistic_index_id: 7, data_type: 'index' },
                           { key: 'eventTheme', label: I18n.t('statistics.event_theme'), statistic_index_id: 4, data_type: 'text' },
                           { key: 'ageRange', label: I18n.t('statistics.age_range'), statistic_index_id: 4, data_type: 'text' }
                         ])
end

unless StatisticField.find_by(key:'groupName').try(:label)
  field = StatisticField.find_or_initialize_by(key: 'groupName')
  field.label = 'Groupe'
  field.statistic_index_id = 1
  field.data_type = 'text'
  field.save!
end

if StatisticType.count.zero?
  StatisticType.create!([
                          { statistic_index_id: 2, key: 'booking', label: I18n.t('statistics.bookings'), graph: true, simple: true },
                          { statistic_index_id: 2, key: 'hour', label: I18n.t('statistics.hours_number'), graph: true, simple: false },
                          { statistic_index_id: 3, key: 'booking', label: I18n.t('statistics.bookings'), graph: false, simple: true },
                          { statistic_index_id: 3, key: 'hour', label: I18n.t('statistics.hours_number'), graph: false, simple: false },
                          { statistic_index_id: 4, key: 'booking', label: I18n.t('statistics.tickets_number'), graph: false,
                            simple: false },
                          { statistic_index_id: 4, key: 'hour', label: I18n.t('statistics.hours_number'), graph: false, simple: false },
                          { statistic_index_id: 5, key: 'member', label: I18n.t('statistics.users'), graph: true, simple: true },
                          { statistic_index_id: 6, key: 'project', label: I18n.t('statistics.projects'), graph: false, simple: true },
                          { statistic_index_id: 7, key: 'revenue', label: I18n.t('statistics.revenue'), graph: false, simple: false }
                        ])
end

if StatisticSubType.count.zero?
  StatisticSubType.create!([
                             { key: 'created', label: I18n.t('statistics.account_creation'),
                               statistic_types: StatisticIndex.find_by(es_type_key: 'account').statistic_types },
                             { key: 'published', label:I18n.t('statistics.project_publication'),
                               statistic_types: StatisticIndex.find_by(es_type_key: 'project').statistic_types }
                           ])
end

if StatisticGraph.count.zero?
  StatisticGraph.create!([
                           { statistic_index_id: 1, chart_type: 'stackedAreaChart', limit: 0 },
                           { statistic_index_id: 2, chart_type: 'stackedAreaChart', limit: 0 },
                           { statistic_index_id: 3, chart_type: 'discreteBarChart', limit: 10 },
                           { statistic_index_id: 4, chart_type: 'discreteBarChart', limit: 10 },
                           { statistic_index_id: 5, chart_type: 'lineChart', limit: 0 },
                           { statistic_index_id: 7, chart_type: 'discreteBarChart', limit: 10 }
                         ])
end

if Group.count.zero?
  Group.create!([
                  { name: 'standard, association', slug: 'standard' },
                  { name: "étudiant, - de 25 ans, enseignant, demandeur d'emploi", slug: 'student' },
                  { name: 'artisan, commerçant, chercheur, auto-entrepreneur', slug: 'merchant' },
                  { name: 'PME, PMI, SARL, SA', slug: 'business' }
                ])
end

Group.create! name: I18n.t('group.admins'), slug: 'admins' unless Group.find_by(slug: 'admins')

# Create the default admin if none exists yet
if Role.where(name: 'admin').joins(:users).count.zero?
  admin = User.new(username: 'admin', email: ENV['ADMIN_EMAIL'], password: ENV['ADMIN_PASSWORD'],
                   password_confirmation: Rails.application.secrets.admin_password, group_id: Group.find_by(slug: 'admins').id,
                   profile_attributes: { first_name: 'admin', last_name: 'admin', phone: '0123456789' },
                   statistic_profile_attributes: { gender: true, birthday: DateTime.current })
  admin.add_role 'admin'
  admin.save!
end

if Component.count.zero?
  Component.create!([
                      { name: 'Silicone' },
                      { name: 'Vinyle' },
                      { name: 'Bois Contre plaqué' },
                      { name: 'Bois Medium' },
                      { name: 'Plexi / PMMA' },
                      { name: 'Flex' },
                      { name: 'Vinyle' },
                      { name: 'Parafine' },
                      { name: 'Fibre de verre' },
                      { name: 'Résine' }
                    ])
end

if Licence.count.zero?
  Licence.create!([
                    { name: 'Attribution (BY)', description: 'Le titulaire des droits autorise toute exploitation de l’œuvre, y compris à' \
                      ' des fins commerciales, ainsi que la création d’œuvres dérivées, dont la distribution est également autorisé sans ' \
                      'restriction, à condition de l’attribuer à son l’auteur en citant son nom. Cette licence est recommandée pour la ' \
                      'diffusion et l’utilisation maximale des œuvres.' },
                    { name: 'Attribution + Pas de modification (BY ND)', description: 'Le titulaire des droits autorise toute utilisation' \
                      ' de l’œuvre originale (y compris à des fins commerciales), mais n’autorise pas la création d’œuvres dérivées.' },
                    { name: "Attribution + Pas d'Utilisation Commerciale + Pas de Modification (BY NC ND)", description: 'Le titulaire ' \
                      'des droits autorise l’utilisation de l’œuvre originale à des fins non commerciales, mais n’autorise pas la ' \
                      'création d’œuvres dérivés.' },
                    { name: "Attribution + Pas d'Utilisation Commerciale (BY NC)", description: 'Le titulaire des droits autorise ' \
                      'l’exploitation de l’œuvre, ainsi que la création d’œuvres dérivées, à condition qu’il ne s’agisse pas d’une ' \
                      'utilisation commerciale (les utilisations commerciales restant soumises à son autorisation).' },
                    { name: "Attribution + Pas d'Utilisation Commerciale + Partage dans les mêmes conditions (BY NC SA)", description:
                      'Le titulaire des droits autorise l’exploitation de l’œuvre originale à des fins non commerciales, ainsi que la ' \
                      'création d’œuvres dérivées, à condition qu’elles soient distribuées sous une licence identique à celle qui régit ' \
                      'l’œuvre originale.' },
                    { name: 'Attribution + Partage dans les mêmes conditions (BY SA)', description: 'Le titulaire des droits autorise ' \
                      'toute utilisation de l’œuvre originale (y compris à des fins commerciales) ainsi que la création d’œuvres dérivées' \
                      ', à condition qu’elles soient distribuées sous une licence identique à celle qui régit l’œuvre originale. Cette' \
                      'licence est souvent comparée aux licences « copyleft » des logiciels libres. C’est la licence utilisée par ' \
                      'Wikipedia.' }
                  ])
end

if Theme.count.zero?
  Theme.create!([
                  { name: 'Vie quotidienne' },
                  { name: 'Robotique' },
                  { name: 'Arduine' },
                  { name: 'Capteurs' },
                  { name: 'Musique' },
                  { name: 'Sport' },
                  { name: 'Autre' }
                ])
end

if Training.count.zero?
  Training.create!([
                     { name: 'Formation Imprimante 3D', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do ' \
                       'eiusmod tempor incididunt ut labore et dolore magna aliqua.' },
                     { name: 'Formation Laser / Vinyle', description: 'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris' \
                       ' nisi ut aliquip ex ea commodo consequat.' },
                     { name: 'Formation Petite fraiseuse numerique', description: 'Duis aute irure dolor in reprehenderit in voluptate ' \
                       'velit esse cillum dolore eu fugiat nulla pariatur.' },
                     { name: 'Formation Shopbot Grande Fraiseuse', description: 'Excepteur sint occaecat cupidatat non proident, sunt in ' \
                       'culpa qui officia deserunt mollit anim id est laborum.' },
                     { name: 'Formation logiciel 2D', description: 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem ' \
                       'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi ' \
                       'architecto beatae vitae dicta sunt explicabo.' }
                   ])

  TrainingsPricing.all.each do |p|
    p.update_columns(amount: (rand * 50 + 5).floor * 100)
  end
end

if Machine.count.zero?
  Machine.create!([
                    { name: 'Découpeuse laser', description: "Préparation à l'utilisation de l'EPILOG Legend 36EXT\r\nInformations" \
                      " générales    \r\n      Pour la découpe, il suffit d'apporter votre fichier vectorisé type illustrator, svg ou dxf" \
                      " avec des \"lignes de coupe\" d'une épaisseur inférieur à 0,01 mm et la machine s'occupera du reste!\r\n     La " \
                      'gravure est basée sur le spectre noir et blanc. Les nuances sont obtenues par différentes profondeurs de gravure ' \
                      "correspondant aux niveaux de gris de votre image. Il suffit pour cela d'apporter une image scannée ou un fichier " \
                      "photo en noir et blanc pour pouvoir reproduire celle-ci sur votre support! \r\nQuels types de matériaux pouvons " \
                      "nous graver/découper?\r\n     Du bois au tissu, du plexiglass au cuir, cette machine permet de découper et graver " \
                      "la plupart des matériaux sauf les métaux. La gravure est néanmoins possible sur les métaux recouverts d'une couche" \
                      " de peinture ou les aluminiums anodisés. \r\n        Concernant l'épaisseur des matériaux découpés, il est " \
                      "préférable de ne pas dépasser 5 mm pour le bois et 6 mm pour le plexiglass.\r\n", spec: "Puissance: 40W\r\nSurface" \
                      " de travail: 914x609 mm \r\nEpaisseur maximale de la matière: 305mm\r\nSource laser: tube laser type CO2\r\n" \
                      'Contrôles de vitesse et de puissance: ces deux paramètres sont ajustables en fonction du matériau (de 1% à 100%) .' \
                      "\r\n", slug: 'decoupeuse-laser' },
                    { name: 'Découpeuse vinyle', description: "Préparation à l'utilisation de la Roland CAMM-1 GX24\r\nInformations " \
                      "générales        \r\n     Envie de réaliser un tee shirt personnalisé ? Un sticker à l'effigie votre groupe " \
                      "préféré ? Un masque pour la réalisation d'un circuit imprimé? Pour cela, il suffit simplement de venir avec votre" \
                      " fichier vectorisé (ne pas oublier de vectoriser les textes) type illustrator svg ou dxf.\r\n \r\nMatériaux " \
                      "utilisés:\r\n    Cette machine permet de découper principalement du vinyle,vinyle réfléchissant, flex.\r\n",
                      spec: "Largeurs de support acceptées: de 50 mm à 700 mm\r\nVitesse de découpe: 50 cm/sec\r\nRésolution mécanique: " \
                      "0,0125 mm/pas\r\n", slug: 'decoupeuse-vinyle' },
                    { name: 'Shopbot / Grande fraiseuse', description: "La fraiseuse numérique ShopBot PRS standard\r\nInformations " \
                      "générales\r\nCette machine est un fraiseuse 3 axes idéale pour l'usinage de pièces de grandes dimensions. De la " \
                      "réalisation d'une chaise ou d'un meuble jusqu'à la construction d'une maison ou d'un assemblage immense, le " \
                      "ShopBot ouvre de nombreuses portes à votre imagination! \r\nMatériaux usinables\r\nLes principaux matériaux " \
                      "usinables sont le bois, le plastique, le laiton et bien d'autres.\r\nCette machine n'usine pas les métaux.\r\n",
                      spec: "Surface maximale de travail: 2440x1220x150 (Z) mm\r\nLogiciel utilisé: Partworks 2D & 3D\r\nRésolution " \
                      "mécanique: 0,015 mm\r\nPrécision de la position: +/- 0,127mm\r\nFormats acceptés: DXF, STL \r\n",
                      slug: 'shopbot-grande-fraiseuse' },
                    { name: 'Imprimante 3D', description: "L'utimaker est une imprimante 3D  low cost utilisant une technologie FFF " \
                      "(Fused Filament Fabrication) avec extrusion thermoplastique.\r\nC'est une machine idéale pour réaliser rapidement " \
                      "des prototypes 3D dans des couleurs différentes.\r\n", spec: "Surface maximale de travail: 210x210x220mm \r\n" \
                      "Résolution méchanique: 0,02 mm \r\nPrécision de position: +/- 0,05 \r\nLogiciel utilisé: Cura\r\nFormats de " \
                      "fichier acceptés: STL \r\nMatériaux utilisés: PLA (en stock).", slug: 'imprimante-3d' },
                    { name: 'Petite Fraiseuse', description: "La fraiseuse numérique Roland Modela MDX-20\r\nInformations générales" \
                      "\r\nCette machine est utilisée  pour l'usinage et le scannage 3D de précision. Elle permet principalement d'usiner" \
                      ' des circuits imprimés et des moules de petite taille. Le faible diamètre des fraises utilisées (Ø 0,3 mm à  Ø 6mm' \
                      ") induit que certains temps d'usinages peuvent êtres long (> 12h), c'est pourquoi cette fraiseuse peut être " \
                      "laissée en autonomie toute une nuit afin d'obtenir le plus précis des usinages au FabLab.\r\nMatériaux usinables:" \
                      "\r\nLes principaux matériaux usinables sont le bois, plâtre, résine, cire usinable, cuivre.\r\n",
                      spec: "Taille du plateau X/Y : 220 mm x 160 mm\r\nVolume maximal de travail: 203,2 mm (X), 152,4 mm (Y), 60,5 mm " \
                      "(Z)\r\nPrécision usinage: 0,00625 mm\r\nPrécision scannage: réglable de 0,05 à 5 mm (axes X,Y) et 0,025 mm (axe Z)" \
                      "\r\nVitesse d'analyse (scannage): 4-15 mm/sec\r\n \r\n \r\nLogiciel utilisé pour le fraisage: Roland Modela player" \
                      " 4 \r\nLogiciel utilisé pour l'usinage de circuits imprimés: Cad.py (linux)\r\nFormats acceptés: STL,PNG 3D\r\n" \
                      "Format d'exportation des données scannées: DXF, VRML, STL, 3DMF, IGES, Grayscale, Point Group et BMP\r\n",
                      slug: 'petite-fraiseuse' },
                  ])

  Price.all.each do |p|
    p.update_columns(amount: (rand * 50 + 5).floor * 100)
  end
end


if Category.count.zero?
  Category.create!(
    [
      { name: 'Stage' },
      { name: 'Atelier' }
    ]
  )
end

unless Setting.find_by(name: 'about_body').try(:value)
  setting = Setting.find_or_initialize_by(name: 'about_body')
  setting.value = '<p>La Fabrique du <a href=\"http://fab-manager.com\" target=\"_blank\">Fab-manager</a> est un' \
  ' atelier de fabrication numérique où l’on peut utiliser des machines de découpe, des imprimantes 3D,… permettant' \
  ' de travailler sur des matériaux variés : plastique, bois, carton, vinyle, … afin de créer toute sorte d’objet grâce' \
  ' à la conception assistée par ordinateur ou à l’électronique.  Mais le Fab Lab est aussi un lieu d’échange de' \
  ' compétences technique. </p>' \
  ' <p>La Fabrique du <a href=\"http://fab-manager.com\" target=\"_blank\">Fab-manager</a> est un espace' \
 ' permanent : ouvert à tous, il offre la possibilité de réaliser des objets soi-même, de partager ses' \
  ' compétences et d’apprendre au contact des médiateurs du Fab Lab et des autres usagers. </p>' \
  '<p>La formation au Fab Lab s’appuie sur des projets et le partage de connaissances : vous devez prendre' \
  ' part à la capitalisation des connaissances et à l’instruction des autres utilisateurs.</p>'
  setting.save
end

unless Setting.find_by(name: 'about_title').try(:value)
  setting = Setting.find_or_initialize_by(name: 'about_title')
  setting.value = 'Imaginer, Fabriquer, <br>Partager à la Fabrique <br> du Fab-manager'
  setting.save
end

unless Setting.find_by(name: 'about_contacts').try(:value)
  setting = Setting.find_or_initialize_by(name: 'about_contacts')
  setting.value = '<dl>' \
  '<dt>Manager Fab Lab :</dt>' \
  '<dd>contact@fab-manager.com</dd>' \
  '<dt>Responsable médiation :</dt>' \
  '<dd>contact@fab-manager.com</dd>' \
  '<dt>Animateur scientifique :</dt>' \
  '<dd>lcontact@fab-manager.com</dd>' \
  '</dl>' \
  '<br><br>' \
  "<p><a href='http://fab-manager.com'>Visitez le site de Fab-manager</a></p>"
  setting.save
end

unless Setting.find_by(name: 'twitter_name').try(:value)
  setting = Setting.find_or_initialize_by(name: 'twitter_name')
  setting.value = 'fab_manager'
  setting.save
end

unless Setting.find_by(name: 'machine_explications_alert').try(:value)
  setting = Setting.find_or_initialize_by(name: 'machine_explications_alert')
  setting.value = "Tout achat d'heure machine est définitif. Aucune" \
  ' annulation ne pourra être effectuée, néanmoins au plus tard 24h avant le créneau fixé, vous pouvez en' \
  " modifier la date et l'horaire à votre convenance et en fonction du calendrier proposé. Passé ce délais," \
  ' aucun changement ne pourra être effectué.'
  setting.save
end

unless Setting.find_by(name: 'training_explications_alert').try(:value)
  setting = Setting.find_or_initialize_by(name: 'training_explications_alert')
  setting.value = 'Toute réservation de formation est définitive.' \
  ' Aucune annulation ne pourra être effectuée, néanmoins au plus tard 24h avant le créneau fixé, vous pouvez' \
  " en modifier la date et l'horaire à votre convenance et en fonction du calendrier proposé. Passé ce délais," \
  ' aucun changement ne pourra être effectué.'
  setting.save
end

unless Setting.find_by(name: 'subscription_explications_alert').try(:value)
  setting = Setting.find_or_initialize_by(name: 'subscription_explications_alert')
  setting.value = '<p><b>Règle sur la date de début des abonnements</b><br></p><ul><li>' \
  ' <span style=\"font-size: 1.6rem; line-height: 2.4rem;\">Si vous êtes un nouvel utilisateur - i.e aucune ' \
  " formation d'enregistrée sur le site - votre abonnement débutera à la date de réservation de votre première " \
  ' formation.</span><br></li><li><span style=\"font-size: 1.6rem; line-height: 2.4rem;\">Si vous avez déjà une ' \
  " formation ou plus de validée, votre abonnement débutera à la date de votre achat d'abonnement.</span></li>" \
  " </ul><p>Merci de bien prendre ses informations en compte, et merci de votre compréhension. L'équipe du Fab Lab.<br>" \
  ' </p><p></p>'
  setting.save
end

unless Setting.find_by(name: 'invoice_logo').try(:value)
  setting = Setting.find_or_initialize_by(name: 'invoice_logo')
  setting.value = 'iVBORw0KGgoAAAANSUhEUgAAAG0AAABZCAYAAAA0E6rtAAAACXBIWXMAAAsTAAALEwEAmpwYAAA57WlUWHRYTUw6Y29tLmFkb2JlLnhtc' \
                  'AAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PS' \
                  'JhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxMzggNzkuMTU5ODI0LCAyMDE2LzA5LzE0LTAxOjA5OjA' \
                  'xICAgICAgICAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMi' \
                  'PgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb' \
                  '20veGFwLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIKICAgICAgICAgIC' \
                  'AgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIgogICAgICAgICAgICB4bWxuczp4bXBNTT0' \
                  'iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIKICAgICAgICAgICAgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20v' \
                  'eGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmL' \
                  'zEuMC8iCiAgICAgICAgICAgIHhtbG5zOmV4aWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZXhpZi8xLjAvIj4KICAgICAgICAgPHhtcDpDcm' \
                  'VhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNyAoV2luZG93cyk8L3htcDpDcmVhdG9yVG9vbD4KICAgICAgICAgPHhtcDpDcmV' \
                  'hdGVEYXRlPjIwMTctMDEtMDNUMTE6MTg6MTgrMDE6MDA8L3htcDpDcmVhdGVEYXRlPgogICAgICAgICA8eG1wOk1vZGlmeURhdGU'
  setting.save
end

unless Setting.find_by(name: 'invoice_reference').try(:value)
  setting = Setting.find_or_initialize_by(name: 'invoice_reference')
  setting.value = 'YYMMmmmX[/VL]R[/A]'
  setting.save
end

unless Setting.find_by(name: 'invoice_code-active').try(:value)
  setting = Setting.find_or_initialize_by(name: 'invoice_code-active')
  setting.value = 'true'
  setting.save
end

unless Setting.find_by(name: 'invoice_code-value').try(:value)
  setting = Setting.find_or_initialize_by(name: 'invoice_code-value')
  setting.value = 'INMEDFABLAB'
  setting.save
end

unless Setting.find_by(name: 'invoice_order-nb').try(:value)
  setting = Setting.find_or_initialize_by(name: 'invoice_order-nb')
  setting.value = 'nnnnnn-MM-YY'
  setting.save
end

unless Setting.find_by(name: 'invoice_VAT-active').try(:value)
  setting = Setting.find_or_initialize_by(name: 'invoice_VAT-active')
  setting.value = 'false'
  setting.save
end

unless Setting.find_by(name: 'invoice_VAT-rate').try(:value)
  setting = Setting.find_or_initialize_by(name: 'invoice_VAT-rate')
  setting.value = '20.0'
  setting.save
end

unless Setting.find_by(name: 'invoice_text').try(:value)
  setting = Setting.find_or_initialize_by(name: 'invoice_text')
  setting.value = "Notre association n'est pas assujettie à la TVA"
  setting.save
end

unless Setting.find_by(name: 'invoice_legals').try(:value)
  setting = Setting.find_or_initialize_by(name: 'invoice_legals')
  setting.value = 'La fabrique<br/>' \
                  '68 rue Louise Michel 38100 GRENOBLE France<br/>' \
                  'Tél. : +33 1 23 45 67 98<br/>' \
                  'Fax. : +33 1 23 45 67 98<br/>' \
                  'SIRET : 237 082 474 00006 - APE 913 E'
  setting.save
end

unless Setting.find_by(name: 'booking_window_start').try(:value)
  setting = Setting.find_or_initialize_by(name: 'booking_window_start')
  setting.value = '1970-01-01 08:00:00'
  setting.save
end

unless Setting.find_by(name: 'booking_window_end').try(:value)
  setting = Setting.find_or_initialize_by(name: 'booking_window_end')
  setting.value = '1970-01-01 23:59:59'
  setting.save
end

unless Setting.find_by(name: 'booking_move_enable').try(:value)
  setting = Setting.find_or_initialize_by(name: 'booking_move_enable')
  setting.value = 'true'
  setting.save
end

unless Setting.find_by(name: 'booking_move_delay').try(:value)
  setting = Setting.find_or_initialize_by(name: 'booking_move_delay')
  setting.value = '24'
  setting.save
end

unless Setting.find_by(name: 'booking_cancel_enable').try(:value)
  setting = Setting.find_or_initialize_by(name: 'booking_cancel_enable')
  setting.value = 'false'
  setting.save
end

unless Setting.find_by(name: 'booking_cancel_delay').try(:value)
  setting = Setting.find_or_initialize_by(name: 'booking_cancel_delay')
  setting.value = '24'
  setting.save
end

unless Setting.find_by(name: 'main_color').try(:value)
  setting = Setting.find_or_initialize_by(name: 'main_color')
  setting.value = '#cb1117'
  setting.save
end

unless Setting.find_by(name: 'secondary_color').try(:value)
  setting = Setting.find_or_initialize_by(name: 'secondary_color')
  setting.value = '#ffdd00'
  setting.save
end

Stylesheet.build_sheet!

unless Setting.find_by(name: 'training_information_message').try(:value)
  setting = Setting.find_or_initialize_by(name: 'training_information_message')
  setting.value = "Avant de réserver une formation, nous vous conseillons de consulter nos offres d'abonnement qui" \
                  ' proposent des conditions avantageuses sur le prix des formations et les créneaux machines.'
  setting.save
end


unless Setting.find_by(name: 'fablab_name').try(:value)
  setting = Setting.find_or_initialize_by(name: 'fablab_name')
  setting.value = 'Fabrique'
  setting.save
end

unless Setting.find_by(name: 'name_genre').try(:value)
  setting = Setting.find_or_initialize_by(name: 'name_genre')
  setting.value = 'female'
  setting.save
end


unless DatabaseProvider.count.positive?
  db_provider = DatabaseProvider.new
  db_provider.save

  unless AuthProvider.find_by(providable_type: DatabaseProvider.name)
    provider = AuthProvider.new
    provider.name = 'FabManager'
    provider.providable = db_provider
    provider.status = 'active'
    provider.save
  end
end

unless Setting.find_by(name: 'reminder_enable').try(:value)
  setting = Setting.find_or_initialize_by(name: 'reminder_enable')
  setting.value = 'true'
  setting.save
end

unless Setting.find_by(name: 'reminder_delay').try(:value)
  setting = Setting.find_or_initialize_by(name: 'reminder_delay')
  setting.value = '24'
  setting.save
end

unless Setting.find_by(name: 'visibility_yearly').try(:value)
  setting = Setting.find_or_initialize_by(name: 'visibility_yearly')
  setting.value = '3'
  setting.save
end

unless Setting.find_by(name: 'visibility_others').try(:value)
  setting = Setting.find_or_initialize_by(name: 'visibility_others')
  setting.value = '1'
  setting.save
end

unless Setting.find_by(name: 'display_name_enable').try(:value)
  setting = Setting.find_or_initialize_by(name: 'display_name_enable')
  setting.value = 'false'
  setting.save
end

unless Setting.find_by(name: 'machines_sort_by').try(:value)
  setting = Setting.find_or_initialize_by(name: 'machines_sort_by')
  setting.value = 'default'
  setting.save
end

unless Setting.find_by(name: 'privacy_draft').try(:value)
  setting = Setting.find_or_initialize_by(name: 'privacy_draft')
  setting.value = "<p>La présente politique de confidentialité définit et vous informe de la manière dont _________ utilise et protège les
  informations que vous nous transmettez, le cas échéant, lorsque vous utilisez le présent site accessible à partir de l’URL suivante :
  _________ (ci-après le « Site »).</p><p>Veuillez noter que cette politique de confidentialité est susceptible d’être modifiée ou
  complétée à tout moment par _________, notamment en vue de se conformer à toute évolution législative, réglementaire, jurisprudentielle
  ou technologique. Dans un tel cas, la date de sa mise à jour sera clairement identifiée en tête de la présente politique et l'Utilisateur
  sera informé par courriel. Ces modifications engagent l’Utilisateur dès leur mise en ligne. Il convient par conséquent que l’Utilisateur
  consulte régulièrement la présente politique de confidentialité et d’utilisation des cookies afin de prendre connaissance de ses
  éventuelles modifications.</p><h3>I. DONNÉES PERSONNELLES</h3><p>D’une manière générale, il vous est possible de visiter le site de
  _________ sans communiquer aucune information personnelle vous concernant. En toute hypothèse, vous n’êtes en aucune manière obligé de
  transmettre ces informations à _________.</p><p>Néanmoins, en cas de refus, il se peut que vous ne puissiez pas bénéficier de
  certaines informations ou services que vous avez demandé. A ce titre en effet, _________ peut être amené dans certains cas à vous
  demander de renseigner vos nom, prénom, pseudonyme, sexe, adresse mail, numéro de téléphone, entreprise et date de naissance (ci-après
  vos « Informations Personnelles »). En fournissant ces informations, vous acceptez expressément qu’elles soient traitées par
  _________, aux fins indiquées au point 2 ci-dessous.</p><p>Conformément au Règlement Général sur la Protection des Données (General
  Data Protection Regulation) adopté par le Parlement européen le 14 avril 2016, et à la Loi Informatique et Libertés du 6 janvier 1978
  modifiée, _________ vous informe des points suivants :</p><h4>1. Identité du responsable du traitement</h4><p>Le responsable du
  traitement est (la société/l'association) _________ – (adresse) _________, (code postal) _________ (ville)&nbsp;_________ – (Pays)
  _________ .</p><h4>2. Finalités du traitement</h4><p>_________ est susceptible de traiter vos Informations Personnelles :</p><p>(a)
  aux fins de vous fournir les informations ou les services que vous avez demandés (notamment : l'envoi de notifications relatives à
  vos activités sur le Site, l’envoi de la Newsletter, la correspondance par email, l’envoi d’informations commerciales, livres
  blancs ou encore l’évaluation de votre niveau de satisfaction quant aux services proposés) ;</p><p>(b) aux fins de recueillir des
  informations nous permettant d’améliorer notre Site, nos produits et services (notamment par le biais de cookies) ;</p><p>(c)
  aux fins de pouvoir vous contacter à propos de différents événements relatifs à _________, incluant notamment la mise à jour des
  produits et le support client.</p><h4>3. Destinataires</h4><p>Seul _________ est destinataire de vos Informations Personnelles.
  Celles-ci, que ce soit sous forme individuelle ou agrégée, ne sont jamais transmises à un tiers, nonobstant les sous-traitants
  auxquels _________ fait appel (vous trouverez de plus amples informations à leur sujet au point 7 ci-dessous). Ni _________,
  ni l’un quelconque de ses sous-traitants, ne procèdent à la commercialisation des données personnelles des visiteurs et Utilisateurs de
  son Site.</p><h4>4. Durée de conservation</h4><p>Vos Informations Personnelles sont conservées par _________ uniquement pour le temps
  correspondant à la finalité de la collecte tel qu’indiqué en 2 ci-dessus qui ne saurait en tout état de cause excéder 36 mois.</p><h4>5.
  Droits Informatique et Libertés</h4><p>Vous disposez des droits suivants concernant vos Informations Personnelles, que vous pouvez exercer
  en nous écrivant à l’adresse postale mentionnée au point 1 ou en contactant le délégué à la protection des données, dont l'adresse est
  mentionnée ci-contre.</p><p><b>o Droit d’accès et de communication des données</b></p><p>Vous avez la faculté d’accéder aux Informations
  Personnelles qui vous concernent.</p><p>Cependant, en raison de l’obligation de sécurité et de confidentialité dans le traitement des
  données à caractère personnel qui incombe à _________, vous êtes informé que votre demande sera traitée sous réserve que vous apportiez la
  preuve de votre identité, notamment par la production d’un scan de votre titre d’identité valide (en cas de demande par voie électronique)
  ou d’une photocopie signée de votre titre d’identité valide (en cas de demande adressée par écrit).</p><p>_________ vous informe qu’il
  sera en droit, le cas échéant, de s’opposer aux demandes manifestement abusives (de par leur nombre, leur caractère répétitif ou
  systématique).</p><p>Pour vous aider dans votre démarche, notamment si vous désirez exercer votre droit d’accès par le biais d’une
  demande écrite à l’adresse postale mentionnée au point 1, vous trouverez en cliquant sur le <a
  href=\"https://www.cnil.fr/fr/modele/courrier/exercer-son-droit-dacces\">lien</a> suivant un modèle de courrier élaboré par la Commission
  Nationale de l’Informatique et des Libertés (la « CNIL »).</p><p><b>o Droit de rectification des données</b></p><p>Au titre de ce droit,
  la législation vous habilite à demander la rectification, la mise à jour, le verrouillage ou encore l’effacement des données vous
  concernant qui peuvent s’avérer le cas échéant inexactes, erronées, incomplètes ou obsolètes.</p><p>Egalement, vous pouvez définir des
  directives générales et particulières relatives au sort des données à caractère personnel après votre décès. Le cas échéant, les héritiers
  d’une personne décédée peuvent exiger de prendre en considération le décès de leur proche et/ou de procéder aux mises à jour nécessaires.
  </p><p>Pour vous aider dans votre démarche, notamment si vous désirez exercer, pour votre propre compte ou pour le compte de l’un de vos
  proches défunt, votre droit de rectification par le biais d’une demande écrite à l’adresse postale mentionnée au point 1, vous trouverez
  en cliquant sur le <a href=\"https://www.cnil.fr/fr/modele/courrier/rectifier-des-donnees-inexactes-obsoletes-ou-perimees\">lien</a>
  suivant un modèle de courrier élaboré par la CNIL.</p><p><b>o Droit d’opposition</b></p><p>L’exercice de ce droit n’est possible que dans
  l’une des deux situations suivantes :</p><p>Lorsque l’exercice de ce droit est fondé sur des motifs légitimes ; ou</p><p>Lorsque
  l’exercice de ce droit vise à faire obstacle à ce que les données recueillies soient utilisées à des fins de prospection commerciale.</p>
  <p>Pour vous aider dans votre démarche, notamment si vous désirez exercer votre droit d’opposition par le biais d’une demande écrite
  adressée à l’adresse postale indiquée au point 1, vous trouverez en cliquant sur le <a
  href=\"https://www.cnil.fr/fr/modele/courrier/supprimer-des-informations-vous-concernant-dun-site-internet\">lien</a> suivant un modèle de
  courrier élaboré par la CNIL.</p><h4>6. Délais de réponse</h4><p> _________ s’engage à répondre à votre demande d’accès, de rectification
  ou d’opposition ou toute autre demande complémentaire  d’informations dans un délai raisonnable qui ne saurait dépasser 1 mois à compter
  de la réception de votre demande.</p><h4>7. Prestataires habilités et transfert vers un pays tiers de l’Union Européenne</h4><p>_________
  vous informe qu’il a recours à ses prestataires habilités pour faciliter le recueil et le traitement des données que vous nous avez
  communiqué. Ces prestataires peuvent être situés en dehors de  l’Union Européenne et ont communication des données recueillies par le
  biais des divers formulaires présents sur le Site.</p><p>_________ s’est préalablement assuré de la mise en œuvre par ses prestataires de
  garanties adéquates et du respect de conditions strictes en matière de confidentialité, d’usage et de protection des données. Tout
  particulièrement, la vigilance s’est portée sur l’existence d’un fondement légal pour effectuer un quelconque transfert de données vers un
  pays tiers. A ce titre, l’un de nos prestataires est soumis à (nom de la règle) _________ approuvées par la (nom de l'autorité) _________
  en (année d'approbation)&nbsp;_________.</p><h4>8. Plainte auprès de l’autorité compétente</h4><p>Si vous considérez que _________ ne
  respecte pas ses obligations au regard de vos Informations Personnelles, vous pouvez adresser une plainte ou une demande auprès de
  l’autorité compétente. En France, l’autorité compétente est la CNIL à laquelle vous pouvez adresser une demande par voie électronique en
  cliquant sur le lien suivant : <a href=\"https://www.cnil.fr/fr/plaintes/internet\">https://www.cnil.fr/fr/plaintes/internet</a>.</p>
  <h3>II. POLITIQUE RELATIVE AUX COOKIES</h3><p>Lors de votre première connexion sur le site web de _________, vous êtes avertis par un
  bandeau en bas de votre écran que des informations relatives à votre navigation sont susceptibles d’être enregistrées dans des fichiers
  dénommés « cookies ». Notre politique d’utilisation des cookies vous permet de mieux comprendre les dispositions que nous mettons en œuvre
  en matière de navigation sur notre site web. Elle vous informe notamment sur l’ensemble des cookies présents sur notre site web, leur
  finalité (partie I.) et vous donne la marche à suivre pour les paramétrer (partie II.)</p><h4>1. Informations générales sur les cookies
  présents sur le site de _________</h4><p>_________, en tant qu’éditeur du présent site web, pourra procéder à l’implantation d’un cookie
  sur le disque dur de votre terminal (ordinateur, tablette, mobile etc.) afin de vous garantir une navigation fluide et optimale sur notre
  site Internet.</p><p>Les « cookies » (ou témoins de connexion) sont des petits fichiers texte de taille limitée qui nous permettent de
  reconnaître votre ordinateur, votre tablette ou votre mobile aux fins de personnaliser les services que nous vous proposons.</p><p>Les
  informations recueillies par le biais des cookies ne permettent en aucune manière de vous identifier nominativement. Elles sont utilisées
  exclusivement pour nos besoins propres afin d’améliorer l’interactivité et la performance de notre site web et de vous adresser des
  contenus adaptés à vos centres d’intérêts. Aucune de ces informations ne fait l’objet d’une communication auprès de tiers sauf lorsque
  _________ a obtenu au préalable votre consentement ou bien lorsque la divulgation de ces informations est requise par la loi, sur ordre
  d’un tribunal ou toute autorité administrative ou judiciaire habilitée à en connaître.</p><p>Pour mieux vous éclairer sur les informations
  que les cookies identifient, vous trouverez ci-dessous un tableau listant les différents types de cookies susceptibles d’être utilisés sur
  le site web de _________, leur nom, leur finalité ainsi que leur durée de conservation.</p><h4>2. Configuration de vos préférences sur les
  cookies</h4><p>Vous pouvez accepter ou refuser le dépôt de cookies à tout moment.</p><p>Lors de votre première connexion sur le site web
  de _________, une bannière présentant brièvement des informations relatives au dépôt de cookies et de technologies similaires apparaît en
  bas de votre écran. Cette bannière vous demande de choisir explicitement d'acceptez ou non le dépôt de cookies sur votre terminal.
  </p><p>Après avoir fait votre choix, vous pouvez le modifier ultérieurement&nbsp; en vous connectant à votre compte utilisateur puis en
  naviguant dans la section intitulée « mes paramètres&nbsp;», accessible via un clic sur votre nom, en haut à droite de l'écran.</p>
  <p>Selon le type de cookie en cause, le recueil de votre consentement au dépôt et à la lecture de cookies sur votre terminal peut être
  impératif.</p><h4>a. Les cookies exemptés de consentement</h4><p>Conformément aux recommandations de la Commission Nationale de
  l’Informatique et des Libertés (CNIL), certains cookies sont dispensés du recueil préalable de votre consentement dans la mesure où ils
  sont strictement nécessaires au fonctionnement du site internet ou ont pour finalité exclusive de permettre ou faciliter la communication
  par voie électronique.  Il s’agit des cookies suivants :</p><p><b>o Identifiant de session</b> et&nbsp;<b>authentification</b> sur l'API.
  Ces cookies sont intégralement soumis à la présente politique dans la mesure où ils sont émis et gérés par _________.</p><p>
  <b>o Stripe</b>, permettant de gérer les paiements par carte bancaire et dont la politique de confidentialité est accessible sur ce
  <a href=\"https://stripe.com/fr/privacy\">lien</a>.</p><p><b>o Disqus</b>, permettant de poster des commentaires sur les fiches projet et
  dont la politique de confidentialité est accessible sur ce <a href=\"https://help.disqus.com/articles/1717103-disqus-privacy-policy\">lien
  </a>.</p><h4>b. Les cookies nécessitant le recueil préalable de votre consentement</h4><p>Cette
  exigence concerne les cookies émis par des tiers et qui sont qualifiés de « persistants » dans la mesure où ils demeurent dans votre
  terminal jusqu’à leur effacement ou leur date d’expiration.</p><p>De tels cookies étant émis par des tiers, leur utilisation et leur dépôt
  sont soumis à leurs propres politiques de confidentialité dont vous trouverez un lien ci-dessous. Cette famille de cookie comprend les
  cookies de mesure d’audience (Google Analytics).</p><p>Les cookies de mesure d’audience établissent des statistiques concernant la
  fréquentation et l’utilisation de divers éléments du site web (comme les contenus/pages que vous avez visité).
  Ces données participent à l’amélioration de l’ergonomie du site web de _________. Un outil de mesure d’audience est utilisé sur le
  présent site internet :</p><p><b>o Google Analytics</b> pour gérer les statistiques de visites dont la politique de
  confidentialité est disponible (uniquement en anglais) à partir du <a href=\"https://policies.google.com/privacy?hl=fr&amp;gl=ZZ\">lien
  </a> suivant. </p><h4>c. Vous disposez de divers outils de paramétrage des cookies</h4><p>La plupart
  des navigateurs Internet sont configurés par défaut de façon à ce que le dépôt de cookies soit autorisé. Votre navigateur vous offre
  l’opportunité de modifier ces paramètres standards de manière à ce que l’ensemble des cookies soit rejeté systématiquement ou bien à ce
  qu’une partie seulement des cookies soit acceptée ou refusée en fonction de leur émetteur.</p><p><b>ATTENTION</b> : Nous attirons votre
  attention sur le fait que le refus du dépôt de cookies sur votre terminal est néanmoins susceptible d’altérer votre expérience
  d’utilisateur ainsi que votre accès à certains services ou fonctionnalités du présent site web. Le cas échéant, _________ décline toute
  responsabilité concernant les conséquences liées à la dégradation de vos conditions de navigation qui interviennent en raison de votre
  choix de refuser, supprimer ou bloquer les cookies nécessaires au fonctionnement du site.
  Ces conséquences ne sauraient constituer un dommage et vous ne pourrez prétendre à aucune indemnité de ce fait.</p>
  <p>Votre navigateur vous permet également de supprimer les cookies existants sur votre
  terminal ou encore de vous signaler lorsque de nouveaux cookies sont susceptibles d’être déposés sur votre terminal. Ces paramètres n’ont
  pas d’incidence sur votre navigation mais vous font perdre tout le bénéfice apporté par le cookie.</p><p>Veuillez ci-dessous prendre
  connaissance des multiples outils mis à votre disposition afin que vous puissiez paramétrer les cookies déposés sur votre terminal.</p>
  <h4>d. Le paramétrage de votre navigateur Internet</h4><p>Chaque navigateur Internet propose ses propres paramètres de gestion des
  cookies. Pour savoir de quelle manière modifier vos préférences en matière de cookies, vous trouverez ci-dessous les liens vers l’aide
  nécessaire pour accéder au menu de votre navigateur prévu à cet effet :</p>
  <ul>
    <li><a href=\"https://support.google.com/chrome/answer/95647?hl=fr\">Chrome</a></li>
    <li><a href=\"https://support.mozilla.org/fr/kb/activer-desactiver-cookies\">Firefox</a></li>
    <li><a href=\"https://support.microsoft.com/fr-fr/help/17442/windows-internet-explorer-delete-manage-cookies#ie=ie-11\">Internet
    Explorer</a></li>
    <li><a href=\"http://help.opera.com/Windows/10.20/fr/cookies.html\">Opera</a></li>
    <li><a href=\"https://support.apple.com/kb/PH21411?viewlocale=fr_FR&amp;locale=fr_FR\">Safari</a></li>
  </ul>
  <p>Pour de plus amples informations concernant les outils de maîtrise des cookies, vous pouvez consulter le
  <a href=\"https://www.cnil.fr/fr/cookies-les-outils-pour-les-maitriser\">site internet</a> de la CNIL.</p>"
  setting.save
end

unless Setting.find_by(name: 'fab_analytics').try(:value)
  setting = Setting.find_or_initialize_by(name: 'fab_analytics')
  setting.value = 'true'
  setting.save
end

if StatisticCustomAggregation.count.zero?
  # available reservations hours for machines
  machine_hours = StatisticType.find_by(key: 'hour', statistic_index_id: 2)

  available_hours = StatisticCustomAggregation.new(
    statistic_type_id: machine_hours.id,
    es_index: 'fablab',
    es_type: 'availabilities',
    field: 'available_hours',
    query: '{"size":0, "aggregations":{"%{aggs_name}":{"sum":{"field":"bookable_hours"}}}, "query":{"bool":{"must":[{"range":' \
           '{"start_at":{"gte":"%{start_date}", "lte":"%{end_date}"}}}, {"match":{"available_type":"machines"}}]}}}'
  )
  available_hours.save!

  # available training tickets
  training_bookings = StatisticType.find_by(key: 'booking', statistic_index_id: 3)

  available_tickets = StatisticCustomAggregation.new(
    statistic_type_id: training_bookings.id,
    es_index: 'fablab',
    es_type: 'availabilities',
    field: 'available_tickets',
    query: '{"size":0, "aggregations":{"%{aggs_name}":{"sum":{"field":"nb_total_places"}}}, "query":{"bool":{"must":[{"range":' \
           '{"start_at":{"gte":"%{start_date}", "lte":"%{end_date}"}}}, {"match":{"available_type":"training"}}]}}}'
  )
  available_tickets.save!
end

unless StatisticIndex.find_by(es_type_key: 'space')
  index = StatisticIndex.create!(es_type_key: 'space', label: I18n.t('statistics.spaces'))
  StatisticType.create!([
                          { statistic_index_id: index.id, key: 'booking', label: I18n.t('statistics.bookings'),
                            graph: true, simple: true },
                          { statistic_index_id: index.id, key: 'hour', label: I18n.t('statistics.hours_number'),
                            graph: true, simple: false }
                        ])
end
