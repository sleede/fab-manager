# frozen_string_literal: true

require 'test_helper'
require 'minitest/autorun'
#require 'sidekiq/testing'

class SupportingDocumentsReminderWorkerTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  setup do
 #   Sidekiq::Testing.inline!

    @worker = SupportingDocumentsReminderWorker.new

    group = groups(:group_1)
    @users = User.where(group_id: group.id).members
    @supporting_document_type_1 = SupportingDocumentType.create!(name: "doc1", groups: [group])
    @supporting_document_type_2 = SupportingDocumentType.create!(name: "doc2", groups: [group])
  end

  teardown do
  #  Sidekiq::Testing.fake!
  end

  test 'notify every users who did not upload supporting document files' do
    @users.each do |user|
      assert_nil user.supporting_documents_reminder_sent_at
    end

    assert_enqueued_emails @users.length do
      @worker.perform
    end

    @users.reload.each do |user|
      assert user.supporting_documents_reminder_sent_at
    end

    assert_enqueued_emails 0 do
      @worker.perform
    end
  end

  test 'notify users even if they have uploaded 1 document of the 2' do
    @users.each do |user|
      user.supporting_document_files.create!(supporting_document_type: @supporting_document_type_1,
                                             attachment: fixture_file_upload('document.pdf'))
    end

    assert_enqueued_emails @users.length do
      @worker.perform
    end
  end

  test 'do not notify users if they have uploaded all documents' do
    @users.each do |user|
      user.supporting_document_files.create!(supporting_document_type: @supporting_document_type_1,
                                             attachment: fixture_file_upload('document.pdf'))
      user.supporting_document_files.create!(supporting_document_type: @supporting_document_type_2,
                                             attachment: fixture_file_upload('document.pdf'))
    end

    assert_enqueued_emails 0 do
      @worker.perform
    end
  end

  test 'do not notify users if they were created too recently' do
    @users.update_all(created_at: 2.minutes.ago)

    assert_enqueued_emails 0 do
      @worker.perform
    end
  end
end
