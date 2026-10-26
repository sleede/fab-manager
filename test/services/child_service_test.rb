# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class ChildServiceTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess

  setup do
    @user = users(:user2)
    @child = Child.create!(
      user: @user,
      first_name: 'Arthur',
      last_name: 'Pendelton',
      birthday: 8.years.ago.to_date
    )
    @child_doc_type = SupportingDocumentType.create!(name: 'Child ID', document_type: 'Child')
  end

  test 'update child without supporting_document_files_attributes succeeds when child has existing documents' do
    SupportingDocumentFile.create!(
      supportable: @child,
      supporting_document_type: @child_doc_type,
      attachment: fixture_file_upload('document.pdf', 'application/pdf')
    )

    notifications = []
    NotificationCenter.stub(:call, ->(args) { notifications << args }) do
      success = ChildService.update(@child, { first_name: 'ArthurUpdated' })
      assert success
    end

    assert_equal 'ArthurUpdated', @child.reload.first_name
    assert_empty(notifications.select { |n| n[:type] == 'notify_admin_user_child_supporting_document_files_updated' })
  end

  test 'update child with indexed hash supporting_document_files_attributes sends notification when complete' do
    notifications = []
    NotificationCenter.stub(:call, ->(args) { notifications << args }) do
      params = {
        'first_name' => 'ArthurUpdated',
        'supporting_document_files_attributes' => {
          '0' => {
            'supporting_document_type_id' => @child_doc_type.id,
            'attachment' => fixture_file_upload('document.pdf', 'application/pdf')
          }
        }
      }
      success = ChildService.update(@child, params)
      assert success
    end

    assert_equal 'ArthurUpdated', @child.reload.first_name
    assert_equal(1, notifications.count { |n| n[:type] == 'notify_admin_user_child_supporting_document_files_updated' })
  end

  test 'update child with non-zero indexed hash supporting_document_files_attributes' do
    notifications = []
    NotificationCenter.stub(:call, ->(args) { notifications << args }) do
      params = {
        'supporting_document_files_attributes' => {
          '5' => {
            'supporting_document_type_id' => @child_doc_type.id,
            'attachment' => fixture_file_upload('document.pdf', 'application/pdf')
          }
        }
      }
      success = ChildService.update(@child, params)
      assert success
    end

    assert_equal(1, notifications.count { |n| n[:type] == 'notify_admin_user_child_supporting_document_files_updated' })
  end

  test 'update child with array-formatted supporting_document_files_attributes' do
    notifications = []
    NotificationCenter.stub(:call, ->(args) { notifications << args }) do
      params = {
        'supporting_document_files_attributes' => [
          {
            'supporting_document_type_id' => @child_doc_type.id,
            'attachment' => fixture_file_upload('document.pdf', 'application/pdf')
          }
        ]
      }
      success = ChildService.update(@child, params)
      assert success
    end

    assert_equal(1, notifications.count { |n| n[:type] == 'notify_admin_user_child_supporting_document_files_updated' })
  end

  test 'update child with single-record hash (with id)' do
    file = SupportingDocumentFile.create!(
      supportable: @child,
      supporting_document_type: @child_doc_type,
      attachment: fixture_file_upload('document.pdf', 'application/pdf')
    )

    notifications = []
    NotificationCenter.stub(:call, ->(args) { notifications << args }) do
      params = {
        supporting_document_files_attributes: {
          id: file.id,
          attachment: fixture_file_upload('document2.pdf', 'application/pdf')
        }
      }
      success = ChildService.update(@child, params)
      assert success
    end

    assert_equal(1, notifications.count { |n| n[:type] == 'notify_admin_user_child_supporting_document_files_updated' })
  end

  test 'update child with _destroy flag does not count as new attachment upload' do
    file = SupportingDocumentFile.create!(
      supportable: @child,
      supporting_document_type: @child_doc_type,
      attachment: fixture_file_upload('document.pdf', 'application/pdf')
    )

    notifications = []
    NotificationCenter.stub(:call, ->(args) { notifications << args }) do
      params = {
        supporting_document_files_attributes: [
          {
            id: file.id,
            attachment: fixture_file_upload('document.pdf', 'application/pdf'),
            _destroy: '1'
          }
        ]
      }
      success = ChildService.update(@child, params)
      assert success
    end

    assert_empty(notifications.select { |n| n[:type] == 'notify_admin_user_child_supporting_document_files_updated' })
  end

  test 'update child does not notify when other required documents are still missing' do
    SupportingDocumentType.create!(name: 'Child Health Certificate', document_type: 'Child')

    notifications = []
    NotificationCenter.stub(:call, ->(args) { notifications << args }) do
      params = {
        supporting_document_files_attributes: [
          {
            supporting_document_type_id: @child_doc_type.id,
            attachment: fixture_file_upload('document.pdf', 'application/pdf')
          }
        ]
      }
      success = ChildService.update(@child, params)
      assert success
    end

    assert_empty(notifications.select { |n| n[:type] == 'notify_admin_user_child_supporting_document_files_updated' })
  end

  test 'update child does not notify when child update fails' do
    notifications = []
    NotificationCenter.stub(:call, ->(args) { notifications << args }) do
      params = {
        first_name: '',
        supporting_document_files_attributes: [
          {
            supporting_document_type_id: @child_doc_type.id,
            attachment: fixture_file_upload('document.pdf', 'application/pdf')
          }
        ]
      }
      success = ChildService.update(@child, params)
      assert_not success
    end

    assert_empty notifications
  end

  test 'create child notifies admin and notifies files created when all files present' do
    child = Child.new(
      user: @user,
      first_name: 'NewChild',
      last_name: 'Pendelton',
      birthday: 5.years.ago.to_date,
      supporting_document_files_attributes: [
        {
          supporting_document_type_id: @child_doc_type.id,
          attachment: fixture_file_upload('document.pdf', 'application/pdf')
        }
      ]
    )

    notifications = []
    NotificationCenter.stub(:call, ->(args) { notifications << args }) do
      success = ChildService.create(child)
      assert success
    end

    assert_equal(1, notifications.count { |n| n[:type] == 'notify_admin_child_created' })
    assert_equal(1, notifications.count { |n| n[:type] == 'notify_admin_user_child_supporting_document_files_created' })
  end
end
