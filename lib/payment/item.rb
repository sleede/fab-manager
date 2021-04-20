# frozen_string_literal: true

# Payments module
module Payment; end

# Generic payment object
class Payment::Item
  attr_reader :klass

  def initialize(klass)
    @klass = klass
  end

  def class
    klass
  end

  def retrieve(_id); end
end
