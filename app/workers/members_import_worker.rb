# frozen_string_literal: true

# Will parse the uploaded CSV file and save or update the members described in that file.
# This import will be asynchronously proceed by sidekiq and a notification will be sent to the requesting user when it's done.
class MembersImportWorker
  include Sidekiq::Worker

  def perform(import_id)
    import = Import.find(import_id)

    raise SecurityError, 'Not allowed to import' unless import.user.admin?
    raise KeyError, 'Wrong worker called' unless import.category == 'members'

    Members::ImportService.import(import)

    NotificationCenter.call type: :notify_admin_import_complete,
                            receiver: import.user,
                            attached_object: import
  end
end
