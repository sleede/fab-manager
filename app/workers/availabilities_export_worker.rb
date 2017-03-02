class UsersExportWorker
  include Sidekiq::Worker

  def perform(export_id)
    export = Export.find(export_id)

    unless export.user.is_admin?
      raise SecurityError, 'Not allowed to export'
    end

    unless export.category == 'users'
      raise KeyError, 'Wrong worker called'
    end

    service = UsersExportService.new
    method_name = "export_#{export.export_type}"

    if %w(members subscriptions reservations).include?(export.export_type) and service.respond_to?(method_name)
      service.public_send(method_name, export)

      NotificationCenter.call type: :notify_admin_export_complete,
                              receiver: export.user,
                              attached_object: export
    end

  end
end
