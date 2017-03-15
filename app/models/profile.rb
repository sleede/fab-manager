class Profile < ActiveRecord::Base
  belongs_to :user
  has_one :user_avatar, as: :viewable, dependent: :destroy
  accepts_nested_attributes_for :user_avatar,
                                allow_destroy: true,
                                reject_if: proc { |attributes| attributes['attachment'].blank? }
  has_one :address, as: :placeable, dependent: :destroy
  accepts_nested_attributes_for :address, allow_destroy: true

  has_one :organization, dependent: :destroy
  accepts_nested_attributes_for :organization, allow_destroy: false

  validates :first_name, presence: true, length: { maximum: 30 }
  validates :last_name, presence: true, length: { maximum: 30 }
  validates :gender, :inclusion => {:in => [true, false]}
  validates :birthday, presence: true
  validates_numericality_of :phone, only_integer: true, allow_blank: false

  def full_name
    # if first_name or last_name is nil, the empty string will be used as a temporary replacement
    (first_name || '').humanize.titleize + ' ' + (last_name || '').humanize.titleize
  end

  def to_s
    full_name
  end

  def age
    if birthday.present?
      now = Time.now.utc.to_date
      (now - birthday).to_f / 365.2425
    else
      ''
    end
  end

  def str_gender
    gender ? 'male' : 'female'
  end

  def self.mapping
    # we protect some fields as they are designed to be managed by the system and must not be updated externally
    blacklist = %w(id user_id created_at updated_at)
    # model-relationships must be added manually
    additional = [%w(avatar string), %w(address string), %w(organization_name string), %w(organization_address string)]
    Profile.column_types
        .map{|k,v| [k, v.type.to_s]}
        .delete_if { |col| blacklist.include?(col[0]) }
        .concat(additional)
  end

end
