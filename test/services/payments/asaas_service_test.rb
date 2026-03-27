# frozen_string_literal: true

require 'test_helper'

class Payments::AsaasServiceTest < ActiveSupport::TestCase
  setup do
    @service = Payments::AsaasService.new
    Setting.set('payment_gateway', 'asaas')
    Setting.set('online_payment_module', true)
    Setting.set('asaas_environment', 'sandbox')
    Setting.set('asaas_api_key', 'asaas_test_key')
  end

  test 'create_cart_payment rejects values below Asaas minimum' do
    cart = Struct.new(:payment_schedule).new(nil)

    @service.stub(:debit_amount_from_cart, 499) do
      error = assert_raises(AsaasError) do
        @service.create_cart_payment(cart, User.first, '06667105978')
      end

      assert_equal 'Asaas Pix only supports payments from R$ 5,00.', error.message
    end
  end

  test 'ensure_customer updates existing Asaas customer missing cpf' do
    user = User.members.without_subscription.first
    pgo = user.payment_gateway_object || user.build_payment_gateway_object
    pgo.update!(gateway_object_id: 'cus_test_123', gateway_object_type: 'Asaas::Customer')

    fake_client = Minitest::Mock.new
    fake_client.expect :get, { 'cpfCnpj' => nil }, ['/v3/customers/cus_test_123']

    asaas_service = Minitest::Mock.new
    asaas_service.expect :update_user, nil, [user.id, '06667105978']

    @service.stub(:client, fake_client) do
      Asaas::Service.stub :new, asaas_service do
        assert_equal pgo, @service.send(:ensure_customer, user, '06667105978')
      end
    end

    fake_client.verify
    asaas_service.verify
  end
end
