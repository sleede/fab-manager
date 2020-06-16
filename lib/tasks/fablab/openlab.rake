# frozen_string_literal: true

# OpenLab Projects tasks
namespace :fablab do
  namespace :openlab do
    desc 'bulk and export projects to openlab'
    task bulk_export: :environment do
      if Setting.get('openlab_app_secret').present?
        Project.find_each do |project|
          project.openlab_create
          puts '-> Done'
        end
      else
        warn "Openlab_app_secret was not configured. Export can't be done."
      end
    end
  end
end
