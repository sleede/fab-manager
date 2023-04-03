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
end
