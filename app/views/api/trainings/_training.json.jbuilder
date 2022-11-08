# frozen_string_literal: true

json.extract! training, :id, :name, :description, :machine_ids, :nb_total_places, :public_page, :disabled, :slug
if training.training_image
  json.training_image_attributes do
    json.id training.training_image.id
    json.attachment_name training.training_image.attachment_identifier
    json.attachment_url training.training_image.attachment.url
  end
end
