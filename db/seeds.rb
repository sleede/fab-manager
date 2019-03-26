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
                   profile_attributes: { first_name: 'admin', last_name: 'admin', gender: true, phone: '0123456789', birthday: Time.now })
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
  setting.value = "Avant de réserver une formation, nous vous conseillons de consulter nos offres d'abonnement qui"+
                  ' proposent des conditions avantageuses sur le prix des formations et les heures machines.'
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


unless DatabaseProvider.count > 0
  db_provider = DatabaseProvider.new
  db_provider.save

  unless AuthProvider.find_by(providable_type: DatabaseProvider.name)
    provider = AuthProvider.new
    provider.name = 'Fablab'
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
