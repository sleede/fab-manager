# frozen_string_literal: true

# Raised when trying to create something based on a subscription but it does not exists or is expired
class InvalidSubscriptionError < StandardError
end
