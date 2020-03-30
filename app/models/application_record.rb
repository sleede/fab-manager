# frozen_string_literal: true

# SuperClass for all app models.
# This is a single spot to configure app-wide model behavior.
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end