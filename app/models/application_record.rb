# frozen_string_literal: true

# SuperClass for all app models.
# This is a single spot to configure app-wide model behavior.
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Update attributes with validation context.
  # In Rails you can provide a context while you save, for example: `.save(:step1)`, but no way to
  # provide a context while you update. This method just adds the way to update with validation
  # context.
  #
  # @param attributes [Hash] attributes to assign
  # @param context [*] validation context
  def update_with_context(attributes, context)
    with_transaction_returning_status do
      assign_attributes(attributes)
      save(**{ context: context })
    end
  end
end
