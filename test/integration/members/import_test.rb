# frozen_string_literal: true

require 'test_helper'

class ImportTest < ActionDispatch::IntegrationTest
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'bulk import members through CSV' do
    bulk_csv = fixture_file_upload('members.csv', 'text/csv')
    post '/api/imports/members',
         params: {
           import_members: bulk_csv,
           update_field: 'id'
         }, headers: default_headers

    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check that the returned import was created
    import = json_response(response.body)
    assert_not_nil import[:id], 'no returned id for the import'
    db_import = Import.find(import[:id])
    assert_not_nil db_import

    # run the import synchronously
    worker = MembersImportWorker.new
    worker.perform(import[:id])

    # check the results were written
    db_import.reload
    assert_not_empty db_import.results, 'import results were not written'
    res = db_import.results_hash
    assert_not_nil res[0][:row], 'import result does not contains the imported data row'
    assert_not_nil res[1][:status], 'import result does not contains the operation applied to the row (create/update)'
    assert_not_nil res[1][:result], 'import result does not contains the result of the operation'

    # check the results match the expectations
    assert_not_nil res[1][:user], 'wrong user: victor hugo is expected to have been created in database'
    assert_equal 'create', res[1][:status], 'wrong operation: victor hugo should have been created'
    assert res[1][:result], 'wrong result: operation should have succeeded'
    assert_equal 1, User.where(id: res[1][:user]).count, 'victor hugo was not found in database'
    assert_equal res[0][:row]['external_id'], User.find(res[1][:user]).invoicing_profile.external_id, 'victor hugo has a wrong external ID'

    assert_not_nil res[3][:user], 'wrong user: louise michel is expected to have been created in database'
    assert_equal 'create', res[3][:status], 'wrong operation: louise michel should have been created'
    assert res[3][:result], 'wrong result: operation should have succeeded'
    assert_equal 1, User.where(id: res[3][:user]).count, 'louise michel was not found in database'

    assert_not_nil res[5][:user], 'wrong user: ambroise croizat is expected to have been created in database'
    assert_equal 'create', res[5][:status], 'wrong operation: ambroise croizat should have been created'
    assert res[5][:result], 'wrong result: operation should have succeeded'
    assert_equal 1, User.where(id: res[5][:user]).count, 'ambroise croizat was not found in database'

    assert_nil res[7][:user], 'wrong user: rirette maitrejean is not expected to have been created in database'
    assert_equal 'create', res[7][:status], 'wrong operation: rirette maitrejean should have been created'
    assert_not res[7][:result], 'wrong result: operation should have failed'
    assert_equal 0, Profile.where(last_name: res[6][:row]['last_name']).count, 'rirette maitrejean was found in database'

    assert_match(/can't be blank/, res[8][:email].to_json)
    assert_match(/can't be blank/, res[8][:username].to_json)

    assert_not_nil res[10][:user], 'wrong user: jean dupont is expected to exists in database'
    assert_equal 'update', res[10][:status], 'wrong operation: jean dupont should have been updated'
    assert res[10][:result], 'wrong result: operation should have succeeded'
    assert_equal res[9][:row]['email'], User.find(res[10][:user]).email, 'jean dupont email was not updated'
  end
end
