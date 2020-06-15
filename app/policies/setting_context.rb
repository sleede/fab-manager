# frozen_string_literal: true

# Pundit Additional context to authorize getting a parameter
class SettingContext
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def policy_class
    SettingPolicy
  end
end
