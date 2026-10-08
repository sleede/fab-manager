# frozen_string_literal: true

require 'test_helper'

class ProductsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.find_by(username: 'admin')
    login_as(@admin, scope: :user)
  end

  test 'create a product' do
    name = 'PLA Filament 3mm'
    post '/api/products',
         params: {
           product: {
             name: name,
             slug: 'pla-filament-3mm',
             sku: 'TOL-12953',
             description: '3mm red PLA plastic filament for 3D printing. PLA is a great general purpose filament with great surface ' \
                          'finish, is easy to print, and even biodegradable.',
             is_active: true,
             product_category_id: 3,
             amount: 174,
             quantity_min: 5,
             low_stock_alert: true,
             low_stock_threshold: 100,
             machine_ids: [4, 6],
             product_files_attributes: [
               { attachment: fixture_file_upload('document.pdf', 'application/pdf', true) },
               { attachment: fixture_file_upload('document2.pdf', 'application/pdf', true) }
             ],
             product_images_attributes: [
               { attachment: fixture_file_upload('products/pla-filament.jpg', 'image/jpg'), is_main: true },
               { attachment: fixture_file_upload('products/pla-filament2.jpg', 'image/jpg'), is_main: false }
             ],
             advanced_accounting_attributes: {
               code: '704611',
               analytical_section: '9D441C'
             },
             product_stock_movements_attributes: [
               { stock_type: 'internal', quantity: 100, reason: 'inward_stock' },
               { stock_type: 'external', quantity: 14, reason: 'other_in' }
             ]
           }
         },
         headers: upload_headers

    # Check response format & status
    assert_equal 201, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the poduct was correctly created
    db_product = Product.where(name: name).first
    assert_not_nil db_product
    assert_equal 2, db_product.product_images.count
    assert_equal 2, db_product.product_files.count
    assert_equal name, db_product.name
    assert_equal '704611', db_product.advanced_accounting.code
    assert_equal '9D441C', db_product.advanced_accounting.analytical_section
    assert_not_empty db_product.description
    assert_equal true, db_product.is_active
    assert_equal 3, db_product.product_category_id
    assert_equal 17_400, db_product.amount
    assert_equal 5, db_product.quantity_min
    assert_equal true, db_product.low_stock_alert
    assert_equal 100, db_product.low_stock_threshold
    assert_equal [4, 6], db_product.machine_ids
    assert_equal 'pla-filament-3mm', db_product.slug
    assert_equal 'TOL-12953', db_product.sku
    assert_equal 100, db_product.stock['internal']
    assert_equal 14, db_product.stock['external']
  end

  test 'update a product' do
    db_product = Product.find(3)

    description = '<p>Cette caisse en <strong>bois masif</strong> est vraiment superbe !</p>'
    put '/api/products/3',
        params: {
          product: {
            description: description,
            amount: 52_300,
            product_stock_movements_attributes: [
              { stock_type: 'external', quantity: 20, reason: 'damaged' },
              { stock_type: 'internal', quantity: 1, reason: 'sold' }
            ]
          }
        }.to_json,
        headers: default_headers

    # Check response format & status
    assert_equal 200, response.status, response.body
    assert_match Mime[:json].to_s, response.content_type

    # Check the product was correctly updated
    db_product.reload
    assert_equal description, db_product.description
    assert_equal 80, db_product.stock['external']
    assert_equal 0, db_product.stock['internal']
    product = json_response(response.body)
    assert_equal description, product[:description]
    assert_equal 80, product[:stock][:external]
    assert_equal 0, product[:stock][:internal]
  end

  test 'delete a product' do
    delete '/api/products/3', headers: default_headers
    assert_response :success
    assert_empty response.body
  end

  test 'clone a product' do
    name = 'Panneau de contre-plaqué peuplier 15 mm'
    put '/api/products/15/clone',
        params: {
          product: {
            name: name,
            sku: '12-4614',
            is_active: false
          }
        }.to_json,
        headers: default_headers
    assert_response :success
    assert_match Mime[:json].to_s, response.content_type

    # Check the new product
    product = Product.last
    original = Product.find(15)
    assert_equal name, product.name
    assert_equal '12-4614', product.sku
    assert_not product.is_active
    assert_equal original.product_category_id, product.product_category_id
    assert_equal original.amount, product.amount
    assert_equal original.quantity_min, product.quantity_min
    assert_equal original.low_stock_alert, product.low_stock_alert
    assert_equal 0, product.stock['internal']
    assert_equal 0, product.stock['external']
    assert_not_equal original.slug, product.slug
  end

  test 'list products with sorting, anonymous access, and safe order handling' do
    logout # verify unauthenticated visitor access

    # Setup NULL and 0 amounts to test COALESCE(amount, 0) behavior
    nil_product_id = Product.first.id
    zero_product_id = Product.second.id
    Product.where(id: nil_product_id).update_all(amount: nil)
    Product.where(id: zero_product_id).update_all(amount: 0)

    # 1. Default sorting (created_at desc)
    get '/api/products', headers: default_headers
    assert_response :success
    default_ids = json_response(response.body)[:data].map { |p| p[:id] }
    assert_not_empty default_ids
    assert_equal Product.order(created_at: :desc).page(1).per(12).pluck(:id), default_ids

    # 2. created_at asc
    get '/api/products?sort=created_at-asc', headers: default_headers
    assert_response :success
    created_asc_ids = json_response(response.body)[:data].map { |p| p[:id] }
    assert_equal Product.order(created_at: :asc).page(1).per(12).pluck(:id), created_asc_ids

    # 3. Name asc & desc
    get '/api/products?sort=name-asc', headers: default_headers
    assert_response :success
    names_asc = json_response(response.body)[:data].map { |p| p[:name] }
    assert_not_empty names_asc
    assert_equal Product.order(name: :asc).page(1).per(12).pluck(:name), names_asc

    get '/api/products?sort=name-desc', headers: default_headers
    assert_response :success
    names_desc = json_response(response.body)[:data].map { |p| p[:name] }
    assert_not_empty names_desc
    assert_equal Product.order(name: :desc).page(1).per(12).pluck(:name), names_desc

    # Case-insensitive direction
    get '/api/products?sort=name-ASC', headers: default_headers
    assert_response :success
    assert_equal names_asc, json_response(response.body)[:data].map { |p| p[:name] }

    # 4. Amount asc & desc (validating COALESCE(amount, 0))
    get '/api/products?sort=amount-asc', headers: default_headers
    assert_response :success
    data_asc = json_response(response.body)[:data]
    assert_not_empty data_asc
    amounts_asc = data_asc.map { |p| p[:amount] || 0.0 }
    assert_equal amounts_asc.sort, amounts_asc
    # Verify both nil and zero amount products appear in the zero-value group at the front
    assert_equal 0.0, amounts_asc.first
    assert_includes data_asc.first(2).map { |p| p[:id] }, nil_product_id
    assert_includes data_asc.first(2).map { |p| p[:id] }, zero_product_id

    get '/api/products?sort=amount-desc', headers: default_headers
    assert_response :success
    data_desc = json_response(response.body)[:data]
    assert_not_empty data_desc
    amounts_desc = data_desc.map { |p| p[:amount] || 0.0 }
    assert_equal amounts_desc.sort.reverse, amounts_desc
    # Verify both nil and zero amount products appear in the zero-value group at the end
    assert_equal 0.0, amounts_desc.last
    assert_includes data_desc.last(2).map { |p| p[:id] }, nil_product_id
    assert_includes data_desc.last(2).map { |p| p[:id] }, zero_product_id

    get '/api/products?sort=amount-DESC', headers: default_headers
    assert_response :success
    assert_equal amounts_desc, json_response(response.body)[:data].map { |p| p[:amount] || 0.0 }

    # 5. Invalid key & direction fallback
    get '/api/products?sort=name-invalid', headers: default_headers
    assert_response :success
    assert_equal names_desc, json_response(response.body)[:data].map { |p| p[:name] }

    get '/api/products?sort=invalid_col-asc', headers: default_headers
    assert_response :success
    assert_equal created_asc_ids, json_response(response.body)[:data].map { |p| p[:id] }

    get '/api/products?sort=amount', headers: default_headers
    assert_response :success
    assert_equal amounts_desc, json_response(response.body)[:data].map { |p| p[:amount] || 0.0 }

    get '/api/products?sort=', headers: default_headers
    assert_response :success
    assert_equal default_ids, json_response(response.body)[:data].map { |p| p[:id] }

    # 6. Non-string parameters (Array / Hash) should safely fall back to default
    get '/api/products?sort[]=', headers: default_headers
    assert_response :success
    assert_equal default_ids, json_response(response.body)[:data].map { |p| p[:id] }

    get '/api/products?sort[key]=amount', headers: default_headers
    assert_response :success
    assert_equal default_ids, json_response(response.body)[:data].map { |p| p[:id] }

    # 7. SQL injection payloads: Ensure safe fallback without SQL syntax error or subquery execution
    sql_1 = capture_product_load_sql do
      get '/api/products?sort=amount-desc;+SELECT+1', headers: default_headers
    end
    assert_response :success
    assert_equal amounts_desc, json_response(response.body)[:data].map { |p| p[:amount] || 0.0 }
    assert_match(/ORDER BY COALESCE\("products"\."amount", 0\) DESC/i, sql_1)
    refute_match(/SELECT 1/i, sql_1)

    sql_2 = capture_product_load_sql do
      get '/api/products?sort=amount-desc,+%28SELECT+1%29', headers: default_headers
    end
    assert_response :success
    assert_equal amounts_desc, json_response(response.body)[:data].map { |p| p[:amount] || 0.0 }
    assert_match(/ORDER BY COALESCE\("products"\."amount", 0\) DESC/i, sql_2)
    refute_match(/SELECT 1/i, sql_2)

    sql_3 = capture_product_load_sql do
      get '/api/products?sort=amount-asc,+%28CASE+WHEN+1%3D1+THEN+1+ELSE+0+END%29', headers: default_headers
    end
    assert_response :success
    assert_equal amounts_desc, json_response(response.body)[:data].map { |p| p[:amount] || 0.0 }
    assert_match(/ORDER BY COALESCE\("products"\."amount", 0\) DESC/i, sql_3)
    refute_match(/CASE WHEN/i, sql_3)

    sql_4 = capture_product_load_sql do
      get '/api/products?sort=%28SELECT+1%29-desc', headers: default_headers
    end
    assert_response :success
    assert_equal default_ids, json_response(response.body)[:data].map { |p| p[:id] }
    assert_match(/ORDER BY "products"\."created_at" DESC/i, sql_4)
    refute_match(/SELECT 1/i, sql_4)
  end

  private

  def capture_product_load_sql
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      payload = args.last
      queries << payload[:sql] if payload[:name] == 'Product Load' || (payload[:sql] =~ /FROM\s+"?products"?/i && payload[:sql] !~ /COUNT/i)
    end
    yield
    assert_not_empty queries, 'Expected Product Load SQL query to be captured'
    queries.last
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
