class Credit < ActiveRecord::Base
  belongs_to :creditable, polymorphic: true
  belongs_to :plan
  has_many :users_credits, dependent: :destroy

  validates :creditable_id, uniqueness: { scope: [:creditable_type, :plan_id] }
end
