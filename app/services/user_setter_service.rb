# frozen_string_literal: true

# helpers to assign data to a user
class UserSetterService
  def initialize(user)
    @user = user
  end

  def assign_avatar(data)
    @user.profile.user_avatar ||= UserAvatar.new
    @user.profile.user_avatar.remote_attachment_url = data
  end

  def assign_address(data)
    @user.invoicing_profile ||= InvoicingProfile.new
    @user.invoicing_profile.address ||= Address.new
    @user.invoicing_profile.address.address = data
  end

  def assign_organization_name(data)
    @user.invoicing_profile ||= InvoicingProfile.new
    @user.invoicing_profile.organization ||= Organization.new
    @user.invoicing_profile.organization.name = data
  end

  def assign_organization_address(data)
    @user.invoicing_profile ||= InvoicingProfile.new
    @user.invoicing_profile.organization ||= Organization.new
    @user.invoicing_profile.organization.address ||= Address.new
    @user.invoicing_profile.organization.address.address = data
  end

  def assign_gender(data)
    @user.statistic_profile ||= StatisticProfile.new
    @user.statistic_profile.gender = data
  end

  def assign_birthday(data)
    @user.statistic_profile ||= StatisticProfile.new
    @user.statistic_profile.birthday = data
  end

  def assign_profile_attribute(attribute, data)
    @user.profile[attribute[8..].to_sym] = data
  end

  def assign_user_attribute(attribute, data)
    @user[attribute[5..].to_sym] = data
  end

  def assign_attibute(attribute, data)
    if attribute.to_s.start_with? 'user.'
      assign_user_attribute(attribute, data)
    elsif attribute.to_s.start_with? 'profile.'
      case attribute.to_s
      when 'profile.avatar'
        assign_avatar(data)
      when 'profile.address'
        assign_address(data)
      when 'profile.organization_name'
        assign_organization_name(data)
      when 'profile.organization_address'
        assign_organization_address(data)
      when 'profile.gender'
        assign_gender(data)
      when 'profile.birthday'
        assign_birthday(data)
      else
        assign_profile_attribute(attribute, data)
      end
    end
  end
end
