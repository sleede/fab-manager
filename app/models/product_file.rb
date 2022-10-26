# frozen_string_literal: true

# ProductFile is a file stored on the file system, associated with a Product.
class ProductFile < Asset
  mount_uploader :attachment, ProductFileUploader
end
