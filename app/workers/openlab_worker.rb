# frozen_string_literal: true

# Asynchronously synchronize the projects with OpenLab-Projects
class OpenlabWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: true

  LOGGER = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil

  def initialize
    client = Openlab::Client.new(app_secret: Setting.get('openlab_app_secret'))
    @projets = Openlab::Projects.new(client)
    super
  end

  def perform(action, project_id)
    LOGGER&.debug ['Openlab sync', action, "project ID: #{project_id}"]

    case action.to_s
    when /create/
      project = Project.find(project_id)
      response = @projets.create(project.openlab_attributes)
    when /update/
      project = Project.find(project_id)
      response = @projets.update(project_id, project.openlab_attributes)
    when /destroy/
      response = @projets.destroy(project_id)
    else
      raise NotImplementedError
    end

    LOGGER&.debug ['Openlab sync', 'RESPONSE ERROR', response.inspect] unless response.success?
  end
end
