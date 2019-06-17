# frozen_string_literal: true

# Asynchronously export all the availabilities to an excel sheet
class AvailabilitiesExportWorker
  include Sidekiq::Worker

  def perform(export_id)
    export = Export.find(export_id)

    raise SecurityError, 'Not allowed to export' unless export.user.admin?

    raise KeyError, 'Wrong worker called' unless export.category == 'availabilities'

    service = AvailabilitiesExportService.new
    method_name = "export_#{export.export_type}"

    return unless %w[index].include?(export.export_type) && service.respond_to?(method_name)

    service.public_send(method_name, export)

    NotificationCenter.call type: :notify_admin_export_complete,
                            receiver: export.user,
                            attached_object: export
  end
end
