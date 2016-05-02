namespace :fablab do
  namespace :openlab do
    task bulk_export: :environment do
      if Rails.application.secrets.openlab_app_secret.present?
        Project.find_each do |project|
          project.openlab_create
        end
      else
        warn "Rails.application.secrets.openlab_app_secret not present. Export can't be done."
      end
    end
  end
end
