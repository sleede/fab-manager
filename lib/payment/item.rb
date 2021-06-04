# frozen_string_literal: true

# Payments module
module Payment; end

# Generic payment object
class Payment::Item
  attr_reader :klass

  def initialize(klass, id = nil, *args)
    @klass = klass
    @id = id
    @args = args
  end

  def class
    klass
  end

  def payment_mean?
    false
  end

  def subscription?
    false
  end

  def order?
    false
  end

  def retrieve(_id = nil, *_args); end
end
