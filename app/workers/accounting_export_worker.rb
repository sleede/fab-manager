# frozen_string_literal: true

# Asynchronously export the accounting data (Invoices & Avoirs) to an external accounting software
class AccountingExportWorker
  include Sidekiq::Worker

  def perform(export_id)
    export = Export.find(export_id)

    raise SecurityError, 'Not allowed to export' unless export.user.admin?

    data = JSON.parse(export.query)
    service = AccountingExportService.new(export.file, data['columns'], data['encoding'], export.extension, export.key)

    service.export(data['start_date'], data['end_date'])

    NotificationCenter.call type: :notify_admin_export_complete,
                            receiver: export.user,
                            attached_object: export
  end
end
