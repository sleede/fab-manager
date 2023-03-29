# frozen_string_literal: true

# This file fills the database with some initial data.
# Some of them are just some placeholders to prevent having an empty palce when starting fab-manager first.
# Other data are required default values, for various settings.

load Rails.root.join('db/seeds/statistics.rb')
load Rails.root.join('db/seeds/notification_types.rb')

if Group.count.zero?
  Group.create!([
                  { name: 'standard, association', slug: 'standard' },
                  { name: "étudiant, - de 25 ans, enseignant, demandeur d'emploi", slug: 'student' },
                  { name: 'artisan, commerçant, chercheur, auto-entrepreneur', slug: 'merchant' },
                  { name: 'PME, PMI, SARL, SA', slug: 'business' }
                ])
end

# Create the default admin if none exists yet
if Role.where(name: 'admin').joins(:users).count.zero?
  admin = User.new(username: 'admin', email: ENV.fetch('ADMIN_EMAIL', nil), password: ENV.fetch('ADMIN_PASSWORD', nil),
                   password_confirmation: Rails.application.secrets.admin_password, group_id: Group.first.id,
                   profile_attributes: { first_name: 'admin', last_name: 'admin', phone: '0123456789' },
                   statistic_profile_attributes: { gender: true, birthday: Date.current })
  admin.add_role 'admin'
  admin.save!
end

load Rails.root.join('db/seeds/settings.rb')

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
                    {
                      name: 'Attribution (BY)',
                      description:
                        'Le titulaire des droits autorise toute exploitation de l’œuvre, y compris à des ' \
                        'fins commerciales, ainsi que la création d’œuvres dérivées, dont la distribution est également autorisé sans ' \
                        'restriction, à condition de l’attribuer à son l’auteur en citant son nom. Cette licence est recommandée pour la ' \
                        'diffusion et l’utilisation maximale des œuvres.'
                    },
                    {
                      name: 'Attribution + Pas de modification (BY ND)',
                      description:
                        'Le titulaire des droits autorise toute utilisation de l’œuvre originale (y compris à des fins commerciales), ' \
                        'mais n’autorise pas la création d’œuvres dérivées.'
                    },
                    {
                      name: "Attribution + Pas d'Utilisation Commerciale + Pas de Modification (BY NC ND)",
                      description:
                        'Le titulaire des droits autorise l’utilisation de l’œuvre originale à des fins non commerciales, ' \
                        'mais n’autorise pas la création d’œuvres dérivés.'
                    },
                    {
                      name: "Attribution + Pas d'Utilisation Commerciale (BY NC)",
                      description:
                        'Le titulaire des droits autorise l’exploitation de l’œuvre, ainsi que la création d’œuvres dérivées, ' \
                        'à condition qu’il ne s’agisse pas d’une utilisation commerciale (les utilisations commerciales ' \
                        'restant soumises à son autorisation).'
                    },
                    {
                      name: "Attribution + Pas d'Utilisation Commerciale + Partage dans les mêmes conditions (BY NC SA)",
                      description:
                        'Le titulaire des droits autorise l’exploitation de l’œuvre originale à des fins non commerciales, ainsi que la ' \
                        'création d’œuvres dérivées, à condition qu’elles soient distribuées sous une licence identique à celle qui ' \
                        'régit l’œuvre originale.'
                    },
                    {
                      name: 'Attribution + Partage dans les mêmes conditions (BY SA)',
                      description:
                        'Le titulaire des droits autorise toute utilisation de l’œuvre originale (y compris à des fins commerciales) ' \
                        'ainsi que la création d’œuvres dérivées, à condition qu’elles soient distribuées sous une licence identique ' \
                        'à celle qui régit l’œuvre originale. Cette licence est souvent comparée aux licences « copyleft » des logiciels ' \
                        'libres. C’est la licence utilisée par Wikipedia.'
                    }
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

if Status.count.zero?
  Status.create!([
                   { name:  I18n.t('statuses.new') },
                   { name:  I18n.t('statuses.pending') },
                   { name:  I18n.t('statuses.done') },
                   { name:  I18n.t('statuses.abandoned') }
                 ])
end

if Training.count.zero?
  Training.create!([
                     {
                       name: 'Formation Imprimante 3D',
                       description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do ' \
                                    'eiusmod tempor incididunt ut labore et dolore magna aliqua.'
                     },
                     {
                       name: 'Formation Laser / Vinyle',
                       description: 'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris ' \
                                    'nisi ut aliquip ex ea commodo consequat.'
                     },
                     {
                       name: 'Formation Petite fraiseuse numerique',
                       description: 'Duis aute irure dolor in reprehenderit in voluptate ' \
                                    'velit esse cillum dolore eu fugiat nulla pariatur.'
                     },
                     {
                       name: 'Formation Shopbot Grande Fraiseuse',
                       description: 'Excepteur sint occaecat cupidatat non proident, sunt in ' \
                                    'culpa qui officia deserunt mollit anim id est laborum.'
                     },
                     {
                       name: 'Formation logiciel 2D',
                       description: 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem ' \
                                    'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis ' \
                                    'et quasi architecto beatae vitae dicta sunt explicabo.'
                     }
                   ])

  TrainingsPricing.find_each do |p|
    p.update(amount: ((rand * 50) + 5).floor * 100)
  end
end

if Machine.count.zero?
  Machine.create!([
                    {
                      name: 'Découpeuse laser',
                      description:
                        "Préparation à l'utilisation de l'EPILOG Legend 36EXT\r\nInformations générales    \r\n      " \
                        "Pour la découpe, il suffit d'apporter votre fichier vectorisé type illustrator, svg ou dxf avec des " \
                        "\"lignes de coupe\" d'une épaisseur inférieur à 0,01 mm et la machine s'occupera du reste!\r\n     La gravure " \
                        'est basée sur le spectre noir et blanc. Les nuances sont obtenues par différentes profondeurs de gravure ' \
                        "correspondant aux niveaux de gris de votre image. Il suffit pour cela d'apporter une image scannée ou un " \
                        "fichier photo en noir et blanc pour pouvoir reproduire celle-ci sur votre support! \r\nQuels types de " \
                        "matériaux pouvons nous graver/découper?\r\n     Du bois au tissu, du plexiglass au cuir, cette machine " \
                        'permet de découper et graver la plupart des matériaux sauf les métaux. La gravure est néanmoins possible ' \
                        "sur les métaux recouverts d'une couche de peinture ou les aluminiums anodisés. \r\n        " \
                        "Concernant l'épaisseur des matériaux découpés, il est préférable de ne pas dépasser 5 mm pour le bois " \
                        "et 6 mm pour le plexiglass.\r\n",
                      spec:
                        "Puissance: 40W\r\nSurface de travail: 914x609 mm \r\n" \
                        "Epaisseur maximale de la matière: 305mm\r\nSource laser: tube laser type CO2\r\nContrôles de vitesse " \
                        "et de puissance: ces deux paramètres sont ajustables en fonction du matériau (de 1% à 100%).\r\n",
                      slug: 'decoupeuse-laser'
                    },
                    {
                      name: 'Découpeuse vinyle',
                      description:
                        "Préparation à l'utilisation de la Roland CAMM-1 GX24\r\nInformations générales        \r\n     " \
                        "Envie de réaliser un tee shirt personnalisé ? Un sticker à l'effigie votre groupe préféré ? " \
                        "Un masque pour la réalisation d'un circuit imprimé? Pour cela, il suffit simplement de venir avec votre " \
                        "fichier vectorisé (ne pas oublier de vectoriser les textes) type illustrator svg ou dxf.\r\n \r\nMatériaux " \
                        "utilisés:\r\n    Cette machine permet de découper principalement du vinyle,vinyle réfléchissant, flex.\r\n",
                      spec: "Largeurs de support acceptées: de 50 mm à 700 mm\r\nVitesse de découpe: 50 cm/sec\r\nRésolution mécanique: " \
                            "0,0125 mm/pas\r\n",
                      slug: 'decoupeuse-vinyle'
                    },
                    {
                      name: 'Shopbot / Grande fraiseuse',
                      description:
                        "La fraiseuse numérique ShopBot PRS standard\r\nInformations " \
                        "générales\r\nCette machine est un fraiseuse 3 axes idéale pour l'usinage de pièces de grandes dimensions. De la " \
                        "réalisation d'une chaise ou d'un meuble jusqu'à la construction d'une maison ou d'un assemblage immense, le " \
                        "ShopBot ouvre de nombreuses portes à votre imagination! \r\nMatériaux usinables\r\nLes principaux matériaux " \
                        "usinables sont le bois, le plastique, le laiton et bien d'autres.\r\nCette machine n'usine pas les métaux.\r\n",
                      spec: "Surface maximale de travail: 2440x1220x150 (Z) mm\r\nLogiciel utilisé: Partworks 2D & 3D\r\nRésolution " \
                            "mécanique: 0,015 mm\r\nPrécision de la position: +/- 0,127mm\r\nFormats acceptés: DXF, STL \r\n",
                      slug: 'shopbot-grande-fraiseuse'
                    },
                    {
                      name: 'Imprimante 3D',
                      description:
                        "L'utimaker est une imprimante 3D  low cost utilisant une technologie FFF " \
                        "(Fused Filament Fabrication) avec extrusion thermoplastique.\r\nC'est une machine idéale pour réaliser " \
                        "rapidement des prototypes 3D dans des couleurs différentes.\r\n",
                      spec: "Surface maximale de travail: 210x210x220mm \r\n" \
                            "Résolution méchanique: 0,02 mm \r\nPrécision de position: +/- 0,05 \r\nLogiciel utilisé: Cura\r\nFormats de " \
                            "fichier acceptés: STL \r\nMatériaux utilisés: PLA (en stock).",
                      slug: 'imprimante-3d'
                    },
                    {
                      name: 'Petite Fraiseuse',
                      description:
                        "La fraiseuse numérique Roland Modela MDX-20\r\nInformations générales\r\nCette machine est utilisée " \
                        "pour l'usinage et le scannage 3D de précision. Elle permet principalement d'usiner des circuits imprimés " \
                        'et des moules de petite taille. Le faible diamètre des fraises utilisées (Ø 0,3 mm à  Ø 6mm) induit que ' \
                        "certains temps d'usinages peuvent êtres long (> 12h), c'est pourquoi cette fraiseuse peut être laissée en " \
                        "autonomie toute une nuit afin d'obtenir le plus précis des usinages au FabLab.\r\nMatériaux usinables:" \
                        "\r\nLes principaux matériaux usinables sont le bois, plâtre, résine, cire usinable, cuivre.\r\n",
                      spec: "Taille du plateau X/Y : 220 mm x 160 mm\r\nVolume maximal de travail: 203,2 mm (X), 152,4 mm (Y), 60,5 mm " \
                            "(Z)\r\nPrécision usinage: 0,00625 mm\r\nPrécision scannage: réglable de 0,05 à 5 mm (axes X,Y) et 0,025 mm " \
                            "(axe Z)\r\nVitesse d'analyse (scannage): 4-15 mm/sec\r\n \r\n \r\nLogiciel utilisé pour le fraisage: " \
                            "Roland Modela player 4 \r\nLogiciel utilisé pour l'usinage de circuits imprimés: Cad.py (linux)\r\n" \
                            "Formats acceptés: STL,PNG 3D\r\nFormat d'exportation des données scannées: DXF, VRML, STL, 3DMF, IGES, " \
                            "Grayscale, Point Group et BMP\r\n",
                      slug: 'petite-fraiseuse'
                    }
                  ])

  Price.find_each do |p|
    p.update(amount: ((rand * 50) + 5).floor * 100)
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

Stylesheet.build_theme!
Stylesheet.build_home!

unless DatabaseProvider.count.positive?
  db_provider = DatabaseProvider.new
  db_provider.save

  unless AuthProvider.find_by(providable_type: DatabaseProvider.name)
    provider = AuthProvider.new
    provider.name = 'FabManager'
    provider.providable = db_provider
    provider.status = 'active'
    provider.save

    require 'provider_config'
    ProviderConfig.write_active_provider
  end
end

ProfileCustomField.find_or_create_by(label: 'N° SIRET')
ProfileCustomField.find_or_create_by(label: 'Code NAF')
ProfileCustomField.find_or_create_by(label: 'N° TVA intracommunautaire')
ProfileCustomField.find_or_create_by(label: 'N° DUNS')
