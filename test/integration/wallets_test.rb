class WalletsTest < ActionDispatch::IntegrationTest

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @jdupond = User.find_by_username('jdupond')
    login_as(@jdupond, scope: :user)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  test 'get my wallet' do
    get '/api/wallet/my'
    assert_equal 200, response.status
    assert_equal Mime::JSON, response.content_type
    wallet = json_response(response.body)
    assert_equal @jdupond.wallet.user_id, wallet[:user_id]
    assert_equal @jdupond.wallet.amount, wallet[:amount]
  end

  test 'admin can get wallet by user id' do
    @admin = User.find_by_username('admin')
    login_as(@admin, scope: :user)
    @user1 = User.first
    get "/api/wallet/by_user/#{@user1.id}"
    assert_equal 200, response.status
    assert_equal Mime::JSON, response.content_type
    wallet = json_response(response.body)
    assert_equal @user1.wallet.user_id, wallet[:user_id]
    assert_equal @user1.wallet.amount, wallet[:amount]
  end

  test 'cant get wallet of user if not admin' do
    @user1 = User.first
    get "/api/wallet/by_user/#{@user1.id}"
    assert_equal 403, response.status
  end
end
