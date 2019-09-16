# frozen_string_literal: true

# Asynchronously export the accounting data (Invoices & Avoirs) to an external accounting software
class AccountingExportWorker
  include Sidekiq::Worker

  def perform(export_id)
    export = Export.find(export_id)

    raise SecurityError, 'Not allowed to export' unless export.user.admin?

    data = JSON.parse(export.query)
    service = AccountingExportService.new(
      data['columns'],
      encoding: data['encoding'], format: export.extension, separator: export.key, date_format: data['date_format']
    )

    service.export(data['start_date'], data['end_date'], export.file)

    NotificationCenter.call type: :notify_admin_export_complete,
                            receiver: export.user,
                            attached_object: export
  end
end
