# frozen_string_literal: true

# Defines the standard statistics data model.
module StatConcern
  extend ActiveSupport::Concern

  included do
    attribute :type, String
    attribute :subType, String
    attribute :date, String
    attribute :stat, Float
    attribute :userId, Integer
    attribute :gender, String
    attribute :age, Integer
    attribute :group, String
    attribute :groupName, String
  end
end
