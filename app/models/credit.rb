class Credit < ApplicationRecord
  belongs_to :creditable, polymorphic: true
  belongs_to :plan
  has_many :users_credits, dependent: :destroy

  validates :creditable_id, uniqueness: { scope: %i[creditable_type plan_id] }
  validates :hours, numericality: { greater_than_or_equal_to: 0 }, if: :not_training_credit?

  def not_training_credit?
    !creditable_type == 'Training'
  end
end
