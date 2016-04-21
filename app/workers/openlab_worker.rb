class OpenlabWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: true

  Logger = Sidekiq.logger.level == Logger::DEBUG ? Sidekiq.logger : nil
  OPENLAB_CLIENT = Openlab::Projects.new

  def perform(action, project_id)
    logger.debug ["Openlab sync", action, "project ID: #{project_id}"]

    case action.to_s
    when /create/
      project = Project.find(project_id)
      response = OPENLAB_CLIENT.create(project.openlab_attributes)
    when /update/
      project = Project.find(project_id)
      response = OPENLAB_CLIENT.update(project_id, project.openlab_attributes)
    when /destroy/
      response = OPENLAB_CLIENT.destroy(project_id)
    end

    logger.debug ["Openlab sync", "RESPONSE ERROR", response.inspect] unless response.success?
  end
end
