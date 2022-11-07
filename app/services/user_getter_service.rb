# frozen_string_literal: true

# helpers to read data from a user
class UserGetterService
  def initialize(user)
    @user = user
  end

  def read_attribute(attribute)
    parsed = /^(user|profile)\.(.+)$/.match(attribute)
    case parsed[1]
    when 'user'
      @user[parsed[2].to_sym]
    when 'profile'
      case attribute
      when 'profile.avatar'
        @user.profile.user_avatar.remote_attachment_url
      when 'profile.address'
        @user.invoicing_profile.address&.address
      when 'profile.organization_name'
        @user.invoicing_profile.organization&.name
      when 'profile.organization_address'
        @user.invoicing_profile.organization&.address&.address
      when 'profile.gender'
        @user.statistic_profile.gender
      when 'profile.birthday'
        @user.statistic_profile.birthday
      else
        @user.profile[parsed[2].to_sym]
      end
    else
      nil
    end
  end
end
