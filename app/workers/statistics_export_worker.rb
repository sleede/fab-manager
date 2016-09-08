class StatisticsExportWorker
  include Sidekiq::Worker

  def perform(export_id)
    export = Export.find(export_id)

    unless export.user.is_admin?
      raise SecurityError, 'Not allowed to export'
    end

    unless export.category == 'statistics'
      raise KeyError, 'Wrong worker called'
    end

    service = StatisticsExportService.new
    method_name = "export_#{export.export_type}"

    if %w(account event machine project subscription training global).include?(export.export_type) and service.respond_to?(method_name)
      service.public_send(method_name, export)

      NotificationCenter.call type: :notify_admin_export_complete,
                              receiver: export.user,
                              attached_object: export
    end

  end
end
