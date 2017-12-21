module Credits
  class TrainingTest < ActionDispatch::IntegrationTest

    # Called before every test method runs. Can be used
    # to set up fixture information.
    def setup
      admin = User.with_role(:admin).first
      login_as(admin, scope: :user)
    end

    test 'create training credit' do

      # First, we create a new credit
      post '/api/credits',
        {
          credit: {
            creditable_id: 4,
            creditable_type: 'Training',
            plan_id: '1',
          }
        }.to_json,
        default_headers

      # Check response format & status
      assert_equal 201, response.status, response.body
      assert_equal Mime::JSON, response.content_type

      # Check the credit was created correctly
      credit = json_response(response.body)
      c = Credit.where(id: credit[:id]).first
      assert_not_nil c, 'Credit was not created in database'

      # Check that no hours were associated with the credit
      assert_nil c.hours
    end

    test 'create a existing credit' do
      post '/api/credits',
           {
               credit: {
                   creditable_id: 4,
                   creditable_type: 'Training',
                   plan_id: '2',
               }
           }.to_json,
           default_headers

      # Check response format & status
      assert_equal 422, response.status, response.body
      assert_equal Mime::JSON, response.content_type
    end
  end
end