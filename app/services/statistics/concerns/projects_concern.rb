# frozen_string_literal: true

# Provides methods to consolidate data from Projects to use in statistics
module Statistics::Concerns::ProjectsConcern
  extend ActiveSupport::Concern

  class_methods do
    def get_project_themes(project)
      project.themes.map do |t|
        { id: t.id, name: t.name }
      end
    end

    def get_projects_components(project)
      project.components.map do |c|
        { id: c.id, name: c.name }
      end
    end

    def get_projects_machines(project)
      project.machines.map do |m|
        { id: m.id, name: m.name }
      end
    end

    def get_project_users(project)
      sum = 0
      project.project_users.each do |pu|
        sum += 1 if pu.is_valid
      end
      sum
    end

    def get_project_user_names(project)
      project.project_users.map do |project_user|
        { id: project_user.user.id, name: project_user.user.profile.full_name }
      end
    end

    def project_info(project)
      {
        project_id: project.id,
        project_name: project.name,
        project_created_at: project.created_at,
        project_published_at: project.published_at,
        project_licence: {},
        project_themes: get_project_themes(project),
        project_components: get_projects_components(project),
        project_machines: get_projects_machines(project),
        project_users: get_project_users(project),
        project_status: project.status&.name,
        project_user_names: get_project_user_names(project),
      }
    end

    def project_info_stat(project)
      {
        projectId: project[:project_id],
        name: project[:project_name],
        licence: project[:project_licence],
        themes: project[:project_themes],
        components: project[:project_components],
        machines: project[:project_machines],
        users: project[:project_users],
        status: project[:project_status],
        projectUserNames: project[:project_user_names],
      }
    end
  end
end
