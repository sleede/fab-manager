# frozen_string_literal: true

require 'asaas'
require 'asaas/client'
require 'asaas/helper'
require 'payment/service'

# Service helpers around Asaas API objects
class Asaas::Service < Payment::Service
  def create_user(user_id, document = nil)
    user = User.find(user_id)
    return user.payment_gateway_object if user.payment_gateway_object&.gateway_object_type == 'Asaas::Customer'

    attributes = Asaas::Helper.customer_attributes(user)
    attributes[:cpfCnpj] = normalize_document(document) if document.present?

    customer = Asaas::Client.new.post('/v3/customers', attributes)
    pgo = user.payment_gateway_object || user.build_payment_gateway_object
    pgo.update!(gateway_object_id: customer['id'], gateway_object_type: 'Asaas::Customer')
    pgo
  rescue ActiveRecord::RecordNotUnique
    user.reload.payment_gateway_object
  end

  def update_user(user_id, document)
    return if document.blank?

    user = User.find(user_id)
    pgo = user.payment_gateway_object
    return unless pgo&.gateway_object_type == 'Asaas::Customer'

    Asaas::Client.new.put("/v3/customers/#{pgo.gateway_object_id}", {
                            cpfCnpj: normalize_document(document),
                            **Asaas::Helper.customer_attributes(user)
                          })
  end

  private

  def normalize_document(document)
    document.to_s.gsub(/\D/, '')
  end
end
