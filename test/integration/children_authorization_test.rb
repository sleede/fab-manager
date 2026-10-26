# frozen_string_literal: true

require 'test_helper'

class ChildrenAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    Warden.test_reset!
    @attacker = users(:user2) # jdupond (member)
    @victim = users(:user3)   # pdurand (member)
    @child_doc_type = SupportingDocumentType.create!(name: 'Child ID', document_type: 'Child')
  end

  teardown do
    Warden.test_reset!
  end

  test 'member creating child without user_id assigns child to current_user' do
    login_as(@attacker, scope: :user)

    post '/api/children',
         params: {
           child: {
             first_name: 'Alice',
             last_name: 'Dupont',
             birthday: 5.years.ago.to_date
           }
         }

    assert_response :created
    child = Child.find_by(first_name: 'Alice', last_name: 'Dupont')
    assert_not_nil child
    assert_equal @attacker.id, child.user_id
  end

  test 'member attempting to assign victim user_id on child create is ignored' do
    login_as(@attacker, scope: :user)

    post '/api/children',
         params: {
           child: {
             first_name: 'Bob',
             last_name: 'Dupont',
             birthday: 7.years.ago.to_date,
             user_id: @victim.id
           }
         }

    assert_response :created
    child = Child.find_by(first_name: 'Bob', last_name: 'Dupont')
    assert_not_nil child
    assert_equal @attacker.id, child.user_id
    assert_not_equal @victim.id, child.user_id
    assert_equal 0, @victim.children.where(first_name: 'Bob').count
  end

  test 'member cannot manipulate supportable_id or supportable_type in nested supporting document creation' do
    login_as(@attacker, scope: :user)

    test_file = fixture_file_upload('document.pdf', 'application/pdf')

    post '/api/children',
         params: {
           child: {
             first_name: 'Charlie',
             last_name: 'Dupont',
             birthday: 8.years.ago.to_date,
             supporting_document_files_attributes: [
               {
                 supporting_document_type_id: @child_doc_type.id,
                 attachment: test_file,
                 supportable_id: @victim.id,
                 supportable_type: 'User'
               }
             ]
           }
         }

    assert_response :created
    child = Child.find_by(first_name: 'Charlie', last_name: 'Dupont')
    assert_not_nil child
    assert_equal @attacker.id, child.user_id

    doc = child.supporting_document_files.first
    assert_not_nil doc
    assert_equal 'Child', doc.supportable_type
    assert_equal child.id, doc.supportable_id
  end

  test 'member cannot update child user_id to transfer child to victim' do
    child = Child.create!(
      user: @attacker,
      first_name: 'David',
      last_name: 'Dupont',
      birthday: 6.years.ago.to_date
    )

    login_as(@attacker, scope: :user)

    put "/api/children/#{child.id}",
        params: {
          child: {
            first_name: 'DavidUpdated',
            user_id: @victim.id
          }
        }

    assert_response :ok
    child.reload
    assert_equal 'DavidUpdated', child.first_name
    assert_equal @attacker.id, child.user_id
    assert_not_equal @victim.id, child.user_id
  end

  test 'verified child user_id tampering is ignored and validated_at is preserved' do
    validation_time = 2.days.ago.change(usec: 0)
    child = Child.create!(
      user: @attacker,
      first_name: 'Emma',
      last_name: 'Dupont',
      birthday: 4.years.ago.to_date,
      validated_at: validation_time
    )

    login_as(@attacker, scope: :user)

    put "/api/children/#{child.id}",
        params: {
          child: {
            user_id: @victim.id
          }
        }

    assert_response :ok
    child.reload
    assert_equal @attacker.id, child.user_id
    assert_not_nil child.validated_at
    assert_equal validation_time.to_i, child.validated_at.to_i
  end

  test 'member cannot modify victim supporting document file via nested attributes' do
    victim_child = Child.create!(
      user: @victim,
      first_name: 'VictimChild',
      last_name: 'Durand',
      birthday: 5.years.ago.to_date
    )
    victim_doc = SupportingDocumentFile.create!(
      supportable: victim_child,
      supporting_document_type: @child_doc_type,
      attachment: fixture_file_upload('document.pdf', 'application/pdf')
    )

    attacker_child = Child.create!(
      user: @attacker,
      first_name: 'AttackerChild',
      last_name: 'Dupont',
      birthday: 5.years.ago.to_date
    )

    login_as(@attacker, scope: :user)

    # Attempt to delete or hijack victim_doc via nested attributes of attacker_child
    assert_raises(ActiveRecord::RecordNotFound) do
      put "/api/children/#{attacker_child.id}",
          params: {
            child: {
              supporting_document_files_attributes: [
                {
                  id: victim_doc.id,
                  _destroy: '1'
                }
              ]
            }
          }
    end

    victim_doc.reload
    assert_equal victim_child.id, victim_doc.supportable_id
    assert_equal 'Child', victim_doc.supportable_type
  end

  test 'member cannot update another users child' do
    victim_child = Child.create!(
      user: @victim,
      first_name: 'VictimChild',
      last_name: 'Durand',
      birthday: 5.years.ago.to_date
    )

    login_as(@attacker, scope: :user)

    put "/api/children/#{victim_child.id}",
        params: {
          child: {
            first_name: 'HackedName'
          }
        }

    assert_response :forbidden
    assert_equal 'VictimChild', victim_child.reload.first_name
  end
end
