# frozen_string_literal: true

require 'payment/item_builder'

# A link between an object in the local database and another object in the remote payment gateway database
class PaymentGatewayObject < ApplicationRecord
  belongs_to :item, polymorphic: true
  belongs_to :invoice, foreign_type: 'Invoice', foreign_key: 'item_id', inverse_of: :payment_gateway_object
  belongs_to :invoice_item, foreign_type: 'InvoiceItem', foreign_key: 'item_id', inverse_of: :payment_gateway_object
  belongs_to :subscription, foreign_type: 'Subscription', foreign_key: 'item_id', inverse_of: :payment_gateway_object
  belongs_to :payment_schedule, foreign_type: 'PaymentSchedule', foreign_key: 'item_id', inverse_of: :payment_gateway_object
  belongs_to :payment_schedule_item, foreign_type: 'PaymentScheduleItem', foreign_key: 'item_id', inverse_of: :payment_gateway_object
  belongs_to :user, foreign_type: 'User', foreign_key: 'item_id', inverse_of: :payment_gateway_object
  belongs_to :plan, foreign_type: 'Plan', foreign_key: 'item_id', inverse_of: :payment_gateway_object
  belongs_to :machine, foreign_type: 'Machine', foreign_key: 'item_id', inverse_of: :payment_gateway_object
  belongs_to :space, foreign_type: 'Space', foreign_key: 'item_id', inverse_of: :payment_gateway_object
  belongs_to :training, foreign_type: 'Training', foreign_key: 'item_id', inverse_of: :payment_gateway_object
  belongs_to :order, foreign_type: 'Order', foreign_key: 'item_id', inverse_of: :payment_gateway_object

  belongs_to :payment_gateway_object # some objects may require a reference to another object for remote recovery

  def gateway_object
    related_item = payment_gateway_object&.gateway_object_id
    Payment::ItemBuilder.build(gateway_object_type, gateway_object_id, related_item)
  end

  def gateway_object=(object)
    self.gateway_object_id = object.id
    self.gateway_object_type = object.class
  end
end
