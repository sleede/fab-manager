# frozen_string_literal: true

# asynchronously export the statistics to an excel file and send the result by email
class StatisticsExportWorker
  include Sidekiq::Worker

  def perform(export_id)
    export = Export.find(export_id)

    raise SecurityError, 'Not allowed to export' unless export.user.admin?

    raise KeyError, 'Wrong worker called' unless export.category == 'statistics'

    service = StatisticsExportService.new
    method_name = "export_#{export.export_type}"

    unless %w[account event machine project subscription training space global].include?(export.export_type) &&
           service.respond_to?(method_name)
      return
    end

    service.public_send(method_name, export)

    NotificationCenter.call type: :notify_admin_export_complete,
                            receiver: export.user,
                            attached_object: export

  end
end
