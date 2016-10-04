json.extract! @training, :id, :name, :description, :machine_ids, :nb_total_places, :public_page
json.training_image @training.training_image.attachment.large.url if @training.training_image
