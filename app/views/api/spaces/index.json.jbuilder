json.array!(@spaces) do |space|
  json.extract! space, :id, :name, :description, :slug, :default_places, :disabled
  json.space_image space.space_image.attachment.medium.url if space.space_image
end
