class OpenAPI::V1::MachinesDoc < OpenAPI::V1::BaseDoc
  resource_description do
    short 'Machines'
    desc 'Machines of Fab-manager'
    formats FORMATS
    api_version API_VERSION
  end

  doc_for :index do
    api :GET, "/#{API_VERSION}/machines", "Machines index"
    description "Machines index. Order by *created_at* ascendant."
    example <<-EOS
      # /open_api/v1/machines
      {
        "machines": [
          {
            "id": 1,
            "name": "Epilog EXT36 Laser",
            "slug": "decoupeuse-laser",
            "updated_at": "2015-02-17T11:06:00.495+01:00",
            "created_at": "2014-06-30T03:32:31.972+02:00",
            "description": "La découpeuse Laser, EPILOG Legend 36EXT\r\n\r\nInformations générales :\r\nLa découpeuse laser vous permet de découper ou graver des matériaux. \r\n\r\nPour la découpe, il suffit d'apporter votre fichier vectorisé type illustrator, svg ou dxf avec des \"lignes de coupe\" d'une épaisseur inférieure à 0,01 mm et la machine s'occupera du reste!\r\n\r\nLa gravure est basée sur le spectre noir et blanc. Les nuances sont obtenues par différentes profondeurs de gravure correspondant aux niveaux de gris de votre image. Il suffit pour cela d'apporter une image scannée ou un fichier photo en noir et blanc pour pouvoir reproduire celle-ci sur votre support.\r\n\r\nTypes de matériaux gravables/découpeables ?\r\nDu bois au tissu, du plexiglass au cuir, cette machine permet de découper et graver la plupart des matériaux sauf les métaux. La gravure est néanmoins possible sur les métaux recouverts d'une couche de peinture ou les aluminiums anodisés. \r\nConcernant l'épaisseur des matériaux découpés, il est préférable de ne pas dépasser 5 mm pour le bois et 6 mm pour le plexiglass.\r\n",
            "spec": "Puissance : 40W\r\nSurface de travail : 914x609 mm \r\nEpaisseur maximale de la matière : 305mm\r\nSource laser : tube laser type CO2\r\nContrôles de vitesse et de puissance : ces deux paramètres sont ajustables en fonction du matériau (de 1% à 100%) .\r\n"
          },
          {
            "id": 2,
            "name": "Découpeuse vinyle",
            "slug": "decoupeuse-vinyle",
            "updated_at": "2014-06-30T15:10:14.272+02:00",
            "created_at": "2014-06-30T03:32:31.977+02:00",
            "description": "La découpeuse Vinyle, Roland CAMM-1 GX24\r\n\r\nInformations générales :\r\nEnvie de réaliser un tee shirt personnalisé ? Un sticker à l'effigie votre groupe préféré? Un masque pour la réalisation d'un circuit imprimé? Pour cela, il suffit simplement de venir avec votre fichier vectorisé (ne pas oublier de vectoriser les textes) type illustrator svg ou dxf.\r\n \r\nMatériaux utilisés :\r\nCette machine permet de découper principalement : vinyle, vinyle réfléchissant et flex.\r\n",
            "spec": "Largeurs de support acceptées: de 50 mm à 700 mm\r\nVitesse de découpe: 50 cm/sec\r\nRésolution mécanique: 0,0125 mm/pas\r\n"
          },
          {
            "id": 3,
            "name": "Shopbot / Grande fraiseuse",
            "slug": "shopbot-grande-fraiseuse",
            "updated_at": "2014-08-19T11:01:12.919+02:00",
            "created_at": "2014-06-30T03:32:31.982+02:00",
            "description": "La fraiseuse numérique ShopBot PRS standard\r\n\r\nInformations générales :\r\nCette machine est une fraiseuse 3 axes, idéale pour l'usinage de pièces de grandes dimensions. De la réalisation d'une chaise ou d'un meuble à la construction d'une maison ou d'un assemblage immense, le ShopBot ouvre de nombreuses portes à votre imagination ! \r\n\r\nMatériaux usinables :\r\nLes principaux matériaux usinables sont le bois, le plastique, le laiton et bien d'autres.\r\nCette machine n'usine pas les métaux.\r\n<object width=\"560\" height=\"315\"><param name=\"movie\" value=\"//www.youtube.com/v/3h8VPLNapag?hl=fr_FR&amp;version=3\"></param><param name=\"allowFullScreen\" value=\"true\"></param><param name=\"allowscriptaccess\" value=\"always\"></param><embed src=\"//www.youtube.com/v/3h8VPLNapag?hl=fr_FR&amp;version=3\" type=\"application/x-shockwave-flash\" width=\"560\" height=\"315\" allowscriptaccess=\"always\" allowfullscreen=\"true\"></embed></object>",
            "spec": "Surface maximale de travail: 2440x1220x150 (Z) mm\r\nLogiciel utilisé: Partworks 2D & 3D\r\nRésolution mécanique: 0,015 mm\r\nPrécision de la position: +/- 0,127mm\r\nFormats acceptés: DXF, STL \r\n"
          },
          {
            "id": 4,
            "name": "Imprimante 3D - Ultimaker",
            "slug": "imprimante-3d",
            "updated_at": "2014-12-11T15:47:02.215+01:00",
            "created_at": "2014-06-30T03:32:31.986+02:00",
            "description": "L'imprimante 3D ULTIMAKER\r\n\r\nInformations générales :\r\nL'utimaker est une imprimante 3D  peu chère utilisant une technologie FFF (Fused Filament Fabrication) avec extrusion thermoplastique.\r\nC'est une machine idéale pour réaliser rapidement des prototypes 3D dans des couleurs différentes.\r\n",
            "spec": "Surface maximale de travail: 210x210x220mm \r\nRésolution méchanique: 0,02 mm \r\nPrécision de position: +/- 0,05 \r\nLogiciel utilisé: Cura\r\nFormats de fichier acceptés: STL \r\nMatériaux utilisés: PLA (en stock)."
          },
          {
            "id": 5,
            "name": "Petite Fraiseuse",
            "slug": "petite-fraiseuse",
            "updated_at": "2014-06-30T14:33:37.638+02:00",
            "created_at": "2014-06-30T03:32:31.989+02:00",
            "description": "La fraiseuse numérique Roland Modela MDX-20\r\n\r\nInformations générales :\r\nCette machine est utilisée  pour l'usinage et le scannage 3D de précision. Elle permet principalement d'usiner des circuits imprimés et des moules de petite taille. Le faible diamètre des fraises utilisées (Ø 0,3 mm à  Ø 6mm) implique que certains temps d'usinages peuvent êtres long (> 12h), c'est pourquoi cette fraiseuse peut être laissée en autonomie toute une nuit afin d'obtenir le plus précis des usinages au FabLab.\r\n\r\nMatériaux usinables :\r\nLes principaux matériaux usinables sont : bois, plâtre, résine, cire usinable, cuivre.\r\n",
            "spec": "Taille du plateau X/Y : 220 mm x 160 mm\r\nVolume maximal de travail: 203,2 mm (X), 152,4 mm (Y), 60,5 mm (Z)\r\nPrécision usinage: 0,00625 mm\r\nPrécision scannage: réglable de 0,05 à 5 mm (axes X,Y) et 0,025 mm (axe Z)\r\nVitesse d'analyse (scannage): 4-15 mm/sec\r\n \r\n \r\nLogiciel utilisé pour le fraisage: Roland Modela player 4 \r\nLogiciel utilisé pour l'usinage de circuits imprimés: Cad.py (linux)\r\nFormats acceptés: STL,PNG 3D\r\nFormat d'exportation des données scannées: DXF, VRML, STL, 3DMF, IGES, Grayscale, Point Group et BMP\r\n"
          },
          # 
          # ....
          #
          {
            "id": 18,
            "name": "Canon IPF 750",
            "slug": "canon-ipf-750",
            "updated_at": "2015-10-12T18:00:24.254+02:00",
            "created_at": "2015-10-12T18:00:24.254+02:00",
            "description": "PROCHAINEMENT",
            "spec": "36 pouces\r\nType d'encre: Encre pigment et colorant réactive, 5 couleurs (MBK x 2, BK, C, M, Y)\r\nRésolution d'impression maximale:\t2400 × 1200 dpi\r\nVitesse d'impression:\t(A0, Image polychrome)\r\nPapier ordinaire: 0:48 min (mode brouillon), 1:14 min (mode standard)\r\nPapier couché: 1:14 min (mode brouillon), 2:26 min (mode standard), 3:51 min (mode qualité élevée)"
          }
        ]
      }
    EOS
  end
end
