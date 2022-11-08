# frozen_string_literal: true

# ProductImage is an image stored on the file system, associated with a Product.
class ProductImage < Asset
  mount_uploader :attachment, ProductImageUploader
end
