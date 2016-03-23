class UsersCredit < ActiveRecord::Base
  belongs_to :user
  belongs_to :credit

  belongs_to :training_credit, ->{ where('credits.creditable_type = ?', 'Training') }, foreign_key: 'credit_id', class_name: 'Credit'
  belongs_to :machine_credit, ->{ where('credits.creditable_type = ?', 'Machine') }, foreign_key: 'credit_id', class_name: 'Credit'
end
