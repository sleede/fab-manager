# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Encoding: UTF-8

if Group.count == 0
  Group.create!([
                    {name: "standard, membership"},
                    {name: "student - 25 years, teachers, unemployed"},
                    {name: "artisan, trader, researcher, entrepreneur"},
                    {name: "Company"}
                ])
end

if User.find_by(email: "admin@fabmanager.com").nil?
  admin = User.new(username: 'admin', email: 'admin@fabmanager.com', password: 'adminadmin', password_confirmation: 'adminadmin', group_id: Group.first.id,
                   profile_attributes: {first_name: 'Admin', last_name: 'Admin', gender: true, phone: '0000000000', birthday: Time.now})
  #admin.skip_confirmation!
  admin.add_role "admin"
  admin.save
end

if Component.count == 0
  Component.create!([
                        {name: "Silicone"},
                        {name: "Vinyl"},
                        {name: "Plywood"},
                        {name: "Wood"},
                        {name: "Plexi / PMMA"},
                        {name: "Flex"},
                        {name: "Vinyle"},
                        {name: "Paraffin"},
                        {name: "Fiberglass"},
                        {name: "Resin"}
                    ])
end

if Licence.count == 0
  Licence.create!([
                      {name: "Attribution (CC BY)", description: "This license lets others distribute, remix, tweak, and build upon your work, even commercially, as long as they credit you for the original creation. This is the most accommodating of licenses offered. Recommended for maximum dissemination and use of licensed materials."},
                      {name: "Attribution-NoDerivs (CC BY-ND)", description: "This license allows for redistribution, commercial and non-commercial, as long as it is passed along unchanged and in whole, with credit to you."},
                      {name: "Attribution-NonCommercial-NoDerivs (CC BY-NC-ND)", description: "This license is the most restrictive of our six main licenses, only allowing others to download your works and share them with others as long as they credit you, but they can’t change them in any way or use them commercially."},
                      {name: "Attribution-NonCommercial CC BY-NC", description: "This license lets others remix, tweak, and build upon your work non-commercially, and although their new works must also acknowledge you and be non-commercial, they don’t have to license their derivative works on the same terms."},
                      {name: "Attribution-NonCommercial-ShareAlike CC BY-NC-SA", description: "This license lets others remix, tweak, and build upon your work non-commercially, as long as they credit you and license their new creations under the identical terms."},
                      {name: "Attribution-ShareAlike (CC BY-SA)", description: "This license lets others remix, tweak, and build upon your work even for commercial purposes, as long as they credit you and license their new creations under the identical terms. This license is often compared to “copyleft” free and open source software licenses. All new works based on yours will carry the same license, so any derivatives will also allow commercial use. This is the license used by Wikipedia, and is recommended for materials that would benefit from incorporating content from Wikipedia and similarly licensed projects."}
                  ])
end

if Theme.count == 0
  Theme.create!([
                    {name: "Daily life"},
                    {name: "Robotics"},
                    {name: "Arduino"},
                    {name: "Sensors"},
                    {name: "Music"},
                    {name: "Sport"},
                    {name: "other"}
                ])
end

if Machine.count == 0
  Machine.create!([
                      {name: "Laser cutter", description: "Preparing to use a EPILOG Legend 36EXT\r\nGeneral information    \r\n      For cutting, just bring your vector type illustrator file with dxf or svg\"cut lines\" of a thickness less than 0.01 mm and the machine does the rest!\r\n     The engraving is based on the black and white spectrum. The shades are obtained by different engraving depths corresponding to the grayscale image. Simply bring a scanned image or a black and white photo file to reproduce it on your material! \r\nWhat types of materials can we engrave / cut?\r\n     Wood, tissue, plexiglass, leather, this machine can cut and engrave most materials except metals. Engraving is however possible on metals covered with a layer of paint or anodized aluminum.\r\n        Regarding the thickness of cut materials, it is best not to exceed 5 mm to 6 mm for wood and plexiglass.\r\n", spec: "Power: 40W\r\nSwork surface: 914 x 609 mm \r\nMaximum thickness of the material: 305mm\r\nLaser Source: CO2 laser tube kind\r\nSpeed and power controls: these two parameters are adjustable depending on the material (from 1% to 100%).\r\n", slug: "laser-cutter"},
                      {name: "Vinyl cutter", description: "Preparing to Use the Roland CAMM-1 GX24\r\nGeneral information        \r\n     Want to create a custom t-shirt? A sticker with the image your favorite band? A mask for producing a printed circuit? For this, you just have to bring your vectorized file (do not forget to vectorize texts) Type: illustrator, svg, dxf.\r\n \r\nUsed materials:\r\n    This machine can cut mainly vinyl, reflective vinyl, flex.\r\n", spec: "Accepted media widths: from 50 mm to 700mm\r\nCutting speed: 50 cm / sec\r\nMechanical resolution: 0.0125 mm / step\r\n", slug: "vinyl-cutter"},
                      {name: "Shopbot / Milling", description: "The PRS ShopBot standard digital milling machine\r\nGeneral information\r\nThis machine is a milling machine 3 perfect axes for the machining of large pieces. The creation of a chair or furniture to construction of a house or a huge assembly, ShopBot opens many doors to your imagination! \r\nMachinable materials\r\nThe main machinable materials are wood, plastic, brass and many others.\r\nThis machine doesn't machine metals.\r\n", spec: "Maximum working area: 2440x1220x150 (Z) mm \r\nSoftware used: Partworks 2D & 3D\r\nMechanical resolution: 0,015 mm\r\nPosition accuracy: +/- 0,127mm\r\nAccepted formats: DXF, STL \r\n", slug: "shopbot-large-millingmachine"},
                      {name: "3D Printer", description: "The utimaker is a low cost 3D printer using FDM technology (Fused Deposition Modeling) with thermoplastic extrusion.\r\nIt is an ideal machine to quickly create 3D prototypes in different colors.\r\n", spec: "Maximum working area: 210x210x220mm \r\nMechanical resolution: 0,02 mm \r\nTolerance: +/- 0,05 \r\nSoftware used: Cura\r\nFile Formats: STL \r\nUsed materials PLA (in stock).", slug: "3D printer"},
                      {name: "Small milling machine", description: "Digital milling Modela Roland MDX-20\r\nGeneral information\r\nThis machine is used for machining and accurate 3D scanning. It mainly allows to machine printed circuits and small parts. The small diameter cutters used (Ø 0.3 mm to Ø 6mm) induces some time machining can take (> 12 hours), so this milling machine can be left overnight autonomously to obtain the precise machining at FabLab.\r\nMachinable materials:\r\nThe main machinable materials are wood, plaster, resin, machinable wax, copper.\r\n", spec: "Board size X / Y : 220 mm x 160 mm\r\nMaximum workload: 203,2 mm (X), 152,4 mm (Y), 60,5 mm (Z)\r\nPprecision machining: 0,00625 mm\r\nScanner precision adjustable from 0.05 to 5 mm (axes X,Y) and 0,025 mm (Z axis)\r\nSpeed of analysis (scanning): 4-15 mm/sec\r\n \r\n \r\nSoftware used for milling: Roland Modela player 4 \r\nSoftware used for machining printed circuit: Cad.py (linux)\r\nSupported formats: STL, PNG 3D\r\nFExport format of the scanned data: DXF, VRML, STL, 3DMF, IGES, Grayscale, Point Group and BMP\r\n", slug: "small-milling-machine"}
                  ])
end

if Category.count == 0
  Category.create!([
                       {name: "Course"},
                       {name: "Workshop"}
                   ])
end
