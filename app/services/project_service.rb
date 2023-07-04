# frozen_string_literal: true

# Provides methods for Project
class ProjectService
  def search(params, current_user, paginate: true)
    connection = ActiveRecord::Base.connection
    return { error: 'invalid adapter' } unless connection.instance_values['config'][:adapter] == 'postgresql'

    search_from_postgre(params, current_user, paginate: paginate)
  end

  private

  def search_from_postgre(params, current_user, paginate: true)
    query_params = JSON.parse(params[:search] || "{}")

    records = Project.published_or_drafts(current_user&.statistic_profile&.id)
    records = Project.user_projects(current_user&.statistic_profile&.id) if query_params['from'] == 'mine'
    records = Project.collaborations(current_user&.id) if query_params['from'] == 'collaboration'

    records = records.with_machine(query_params['machine_id']) if query_params['machine_id'].present?
    records = records.with_component(query_params['component_id']) if query_params['component_id'].present?
    records = records.with_theme(query_params['theme_id']) if query_params['theme_id'].present?
    records = records.with_project_category(query_params['project_category_id']) if query_params['project_category_id'].present?
    records = records.with_space(query_params['space_id']) if query_params['space_id'].present?
    records = records.with_status(query_params['status_id']) if query_params['status_id'].present?

    if query_params['member_id'].present?
      member = User.find(query_params['member_id'])
      if member
        records = records.where(id: Project.user_projects(member.statistic_profile.id)).or(Project.where(id: Project.collaborations(member.id)))
      end
    end

    created_from = Time.zone.parse(query_params['from_date']).beginning_of_day if query_params['from_date'].present?
    created_to = Time.zone.parse(query_params['to_date']).end_of_day if query_params['to_date'].present?
    if created_from || created_to
      records = records.where(created_at: created_from..created_to)
    end

    records = if query_params['q'].present?
                records.search(query_params['q'])
              else
                records.order(created_at: :desc)
              end

    records = records.includes(:users, :project_image)
    records = records.page(params[:page]) if paginate

    { total: records.count, projects: records }
  end
end
