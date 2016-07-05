class WalletsTest < ActionDispatch::IntegrationTest

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @kdumas = User.find_by(username: 'kdumas')
    login_as(@kdumas, scope: :user)
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
    assert_equal @kdumas.wallet.user_id, wallet[:user_id]
    assert_equal @kdumas.wallet.amount, wallet[:amount]
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

  test 'cant get wallet of an user if not admin' do
    user5 = users(:user_5)
    get "/api/wallet/by_user/#{user5.id}"
    assert_equal 403, response.status
  end

  test 'get all transactions of wallet' do
    w = @kdumas.wallet
    get "/api/wallet/#{w.id}/transactions"
    assert_equal 200, response.status
    assert_equal Mime::JSON, response.content_type
    transactions = json_response(response.body)
    assert_equal w.wallet_transactions.count, transactions.size
    assert_equal wallet_transactions(:transaction1).id, transactions.first[:id]
  end

  test 'only admin and wallet owner can show their transactions' do
    user5 = users(:user_5)
    get "/api/wallet/#{user5.wallet.id}/transactions"
    assert_equal 403, response.status
  end
end
