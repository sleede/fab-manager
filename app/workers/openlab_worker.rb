class OpenlabWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: true

  Logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
  openlab_client = Openlab::Projects.new

  def perform(action, project_id)
    logger.debug ["Openlab sync", action, "project ID: #{project_id}"]

    case action.to_s
    when /create/
      project = Project.find(project_id)
      openlab_client.create(project.openlab_attributes)
    when /update/
      project = Project.find(project_id)
      openlab_client.update(project_id, project.openlab_attributes)
    when /destroy/
      openlab_client.destroy(project_id)
    end
  end
end
