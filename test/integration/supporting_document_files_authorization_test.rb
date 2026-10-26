# frozen_string_literal: true

require 'test_helper'

class SupportingDocumentFilesAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    Warden.test_reset!
    @attacker = users(:user2) # jdupond (member)
    @victim = users(:user3)   # pdurand (member)
    @user_doc_type1 = SupportingDocumentType.create!(name: 'ID Card', document_type: 'User')
    @user_doc_type2 = SupportingDocumentType.create!(name: 'Proof of Address', document_type: 'User')
  end

  teardown do
    Warden.test_reset!
  end

  test 'member cannot create supporting document file for another user' do
    login_as(@attacker, scope: :user)

    test_file = fixture_file_upload('document.pdf', 'application/pdf')

    post '/api/supporting_document_files',
         params: {
           supporting_document_file: {
             supporting_document_type_id: @user_doc_type1.id,
             supportable_id: @victim.id,
             supportable_type: 'User',
             attachment: test_file
           }
         }

    assert_response :forbidden
    assert_equal 0, SupportingDocumentFile.where(supportable_id: @victim.id, supportable_type: 'User').count
  end

  test 'member can create supporting document file for themselves' do
    login_as(@attacker, scope: :user)

    test_file = fixture_file_upload('document.pdf', 'application/pdf')

    post '/api/supporting_document_files',
         params: {
           supporting_document_file: {
             supporting_document_type_id: @user_doc_type1.id,
             supportable_id: @attacker.id,
             supportable_type: 'User',
             attachment: test_file
           }
         }

    assert_response :created
    doc = SupportingDocumentFile.find_by(supportable_id: @attacker.id, supportable_type: 'User')
    assert_not_nil doc
    assert_equal @user_doc_type1.id, doc.supporting_document_type_id
  end

  test 'member updating own supporting document cannot transfer supportable_id or supportable_type' do
    doc = SupportingDocumentFile.create!(
      supportable: @attacker,
      supporting_document_type: @user_doc_type1,
      attachment: fixture_file_upload('document.pdf', 'application/pdf')
    )

    login_as(@attacker, scope: :user)

    put "/api/supporting_document_files/#{doc.id}",
        params: {
          supporting_document_file: {
            supportable_id: @victim.id,
            supportable_type: 'User'
          }
        }

    assert_response :ok
    doc.reload
    assert_equal @attacker.id, doc.supportable_id
    assert_equal 'User', doc.supportable_type
    assert_not_equal @victim.id, doc.supportable_id
  end

  test 'member updating own supporting document cannot reassign to a child' do
    child = Child.create!(
      user: @victim,
      first_name: 'VictimChild',
      last_name: 'Durand',
      birthday: 5.years.ago.to_date
    )

    doc = SupportingDocumentFile.create!(
      supportable: @attacker,
      supporting_document_type: @user_doc_type1,
      attachment: fixture_file_upload('document.pdf', 'application/pdf')
    )

    login_as(@attacker, scope: :user)

    put "/api/supporting_document_files/#{doc.id}",
        params: {
          supporting_document_file: {
            supportable_id: child.id,
            supportable_type: 'Child'
          }
        }

    assert_response :ok
    doc.reload
    assert_equal @attacker.id, doc.supportable_id
    assert_equal 'User', doc.supportable_type
  end

  test 'member can legitimately update document type on own file' do
    doc = SupportingDocumentFile.create!(
      supportable: @attacker,
      supporting_document_type: @user_doc_type1,
      attachment: fixture_file_upload('document.pdf', 'application/pdf')
    )

    login_as(@attacker, scope: :user)

    put "/api/supporting_document_files/#{doc.id}",
        params: {
          supporting_document_file: {
            supporting_document_type_id: @user_doc_type2.id
          }
        }

    assert_response :ok
    doc.reload
    assert_equal @user_doc_type2.id, doc.supporting_document_type_id
    assert_equal @attacker.id, doc.supportable_id
  end

  test 'member cannot update another users supporting document file' do
    victim_doc = SupportingDocumentFile.create!(
      supportable: @victim,
      supporting_document_type: @user_doc_type1,
      attachment: fixture_file_upload('document.pdf', 'application/pdf')
    )

    login_as(@attacker, scope: :user)

    put "/api/supporting_document_files/#{victim_doc.id}",
        params: {
          supporting_document_file: {
            supporting_document_type_id: @user_doc_type2.id
          }
        }

    assert_response :forbidden
    victim_doc.reload
    assert_equal @user_doc_type1.id, victim_doc.supporting_document_type_id
  end
end
