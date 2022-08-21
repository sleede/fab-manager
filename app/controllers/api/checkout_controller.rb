# frozen_string_literal: true

# API Controller for cart checkout
class API::CheckoutController < API::ApiController
  include ::API::OrderConcern
end
