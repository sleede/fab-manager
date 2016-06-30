class AgeRange < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :events, dependent: :nullify

  def safe_destroy
    if self.events.count == 0
      destroy
    else
      false
    end
  end
end
