class Profile < ActiveRecord::Base
  belongs_to :user
  has_one :user_avatar, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :user_avatar,
                                allow_destroy: true,
                                reject_if: proc { |attributes| attributes['attachment'].blank? }
  has_one :address, as: :placeable, dependent: :destroy
  accepts_nested_attributes_for :address, allow_destroy: true

  validates :first_name, presence: true, length: { maximum: 30 }
  validates :last_name, presence: true, length: { maximum: 30 }
  validates :gender, :inclusion => {:in => [true, false]}
  validates :birthday, presence: true
  validates_numericality_of :phone, only_integer: true, allow_blank: false

  def full_name
    first_name.humanize.titleize + ' ' + last_name.humanize.titleize
  end

  def to_s
    full_name
  end

  def age
    if birthday.present?
      now = Time.now.utc.to_date
      now.year - birthday.year - (birthday.to_date.change(:year => now.year) > now ? 1 : 0)
    else
      ''
    end
  end

  def str_gender
    gender ? 'male' : 'female'
  end
end
