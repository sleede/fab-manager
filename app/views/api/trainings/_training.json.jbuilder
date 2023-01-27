# frozen_string_literal: true

json.extract! training, :id, :name, :description, :machine_ids, :nb_total_places, :public_page, :disabled, :slug,
              :auto_cancel, :auto_cancel_threshold, :auto_cancel_deadline, :authorization, :authorization_period, :invalidation,
              :invalidation_period
if training.training_image
  json.training_image_attributes do
    json.id training.training_image.id
    json.attachment_name training.training_image.attachment_identifier
    json.attachment_url training.training_image.attachment.url
  end
end

if training.advanced_accounting
  json.advanced_accounting_attributes do
    json.partial! 'api/advanced_accounting/advanced_accounting', advanced_accounting: training.advanced_accounting
  end
end
