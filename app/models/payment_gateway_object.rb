# frozen_string_literal: true

# A link between an object in the local database and another object in the remote payment gateway database
class PaymentGatewayObject < ApplicationRecord
  belongs_to :item, polymorphic: true
  belongs_to :gateway_object, polymorphic: true
end
