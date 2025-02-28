# frozen_string_literal: true

# OpenLab Projects tasks
namespace :fablab do
  namespace :openlab do
    desc 'bulk and export projects to openlab'
    task bulk_export: :environment do
      if Setting.get('openlab_app_id').present? && Setting.get('openlab_app_secret').present?
        Project.published.find_each do |project|
          project.openlab_create
          puts '-> Done'
        end
      else
        warn "openlab_app_id or openlab_app_secret was not configured. Export can't be done."
      end
    end

    desc 'bulk update projects to openlab'
    task bulk_update: :environment do
      if Setting.get('openlab_app_id').present? && Setting.get('openlab_app_secret').present?
        Project.published.find_each do |project|
          project.openlab_update
          puts '-> Done'
        end
      else
        warn "openlab_app_id or openlab_app_secret was not configured. Update can't be done."
      end
    end

    desc 'bulk delete projects from openlab'
    task bulk_delete: :environment do
      if Setting.get('openlab_app_id').present? && Setting.get('openlab_app_secret').present?
        Project.find_each do |project|
          project.openlab_destroy
          puts '-> Done'
        end
      else
        warn "openlab_app_id or openlab_app_secret was not configured. Delete can't be done."
      end
    end
  end
end
