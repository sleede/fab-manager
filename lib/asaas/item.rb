# frozen_string_literal: true

require 'asaas'
require 'payment/item'
require 'asaas/client'

# Generic wrapper around Asaas objects
class Asaas::Item < Payment::Item
  def retrieve(id = nil, *_args)
    @id ||= id
    return unless @id

    case klass
    when 'Asaas::Customer'
      Asaas::Client.new.get("/v3/customers/#{@id}")
    when 'Asaas::Payment'
      Asaas::Client.new.get("/v3/payments/#{@id}")
    end
  end
end
