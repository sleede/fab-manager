class ProjectCao < Asset
  mount_uploader :attachment, ProjectCaoUploader

  validates :attachment, file_size: { maximum: 20.megabytes.to_i }
  validates :attachment, :file_mime_type => {
      :content_type => %w(application/pdf application/postscript application/illustrator
                          image/x-eps image/svg+xml application/sla application/dxf application/acad application/dwg
                          application/octet-stream application/step application/iges model/iges x-world/x-3dmf
                          application/ application/vnd.openxmlformats-officedocument.wordprocessingml.document
                          image/png text/x-arduino text/plain application/scad application/vnd.sketchup.skp
                          application/x-koan application/vnd-koan koan/x-skm application/vnd.koan application/x-tex
                          application/x-latex)
  }
end
