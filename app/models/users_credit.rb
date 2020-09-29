# frozen_string_literal: true

# UserCredit is the relation table between a Credit and an User.
# It saves the consumed credits only
class UsersCredit < ApplicationRecord
  belongs_to :user
  belongs_to :credit

  belongs_to :training_credit, -> { where('credits.creditable_type = ?', 'Training') }, foreign_key: 'credit_id', class_name: 'Credit'
  belongs_to :machine_credit, -> { where('credits.creditable_type = ?', 'Machine') }, foreign_key: 'credit_id', class_name: 'Credit'
  belongs_to :space_credit, -> { where('credits.creditable_type = ?', 'Space') }, foreign_key: 'credit_id', class_name: 'Credit'
end
