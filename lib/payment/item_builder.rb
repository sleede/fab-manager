# frozen_string_literal: true

require 'pay_zen/item'
require 'stripe/item'

# Payments module
module Payment; end

# Build the corresponding gateway item, according to the provided klass
class Payment::ItemBuilder
  attr_reader :instance

  def self.build(klass, *ids)
    builder = new(klass, *ids)
    builder.instance
  end

  private

  def initialize(klass, *ids)
    @instance = case klass
                when /^PayZen::/
                  PayZen::Item.new(klass, *ids)
                when /^Stripe::/
                  Stripe::Item.new(klass, *ids)
                else
                  raise TypeError
                end
  end
end
