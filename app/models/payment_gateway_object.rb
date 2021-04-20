# frozen_string_literal: true

require 'payment/item_builder'

# A link between an object in the local database and another object in the remote payment gateway database
class PaymentGatewayObject < ApplicationRecord
  belongs_to :item, polymorphic: true
  belongs_to :invoice, foreign_type: 'Invoice', foreign_key: 'item_id'

  def gateway_object
    item = Payment::ItemBuilder.build(gateway_object_type)
    item.retrieve(gateway_object_id)
  end

  def gateway_object=(object)
    self.gateway_object_id = object.id
    self.gateway_object_type = object.class
  end
end
