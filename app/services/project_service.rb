# frozen_string_literal: true

# Provides methods for Project
class ProjectService

  def search(params, current_user)
    connection = ActiveRecord::Base.connection
    return { error: 'invalid adapter' } unless connection.instance_values['config'][:adapter] == 'postgresql'

    search_from_postgre(params, current_user)
  end

  private

  def search_from_postgre(params, current_user)
    query_params = JSON.parse(params[:search])

    records = Project.published_or_drafts(current_user&.statistic_profile&.id)
    records = Project.user_projects(current_user&.statistic_profile&.id) if query_params['from'] == 'mine'
    records = Project.collaborations(current_user&.id) if query_params['from'] == 'collaboration'

    records = records.with_machine(query_params['machine_id']) if query_params['machine_id'].present?
    records = records.with_component(query_params['component_id']) if query_params['component_id'].present?
    records = records.with_theme(query_params['theme_id']) if query_params['theme_id'].present?
    records = records.with_space(query_params['space_id']) if query_params['space_id'].present?
    records = if query_params['q'].present?
                records.search(query_params['q'])
              else
                records.order(created_at: :desc)
              end

    { total: records.count, projects: records.includes(:users, :project_image).page(params[:page]) }
  end
end