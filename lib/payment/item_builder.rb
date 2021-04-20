# frozen_string_literal: true

require 'pay_zen/item'
require 'stripe/item'

# Payments module
module Payment; end

# Build the corresponding gateway item, according to the provided klass
class Payment::ItemBuilder
  attr_reader :instance

  def self.build(klass)
    builder = new(klass)
    builder.instance
  end

  private

  def initialize(klass)
    @instance = case klass
                when /^PayZen::/
                  PayZen::Item.new(klass)
                when /^Stripe::/
                  Stripe::Item.new(klass)
                else
                  raise TypeError
                end
  end
end
