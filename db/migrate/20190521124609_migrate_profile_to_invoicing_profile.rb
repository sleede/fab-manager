# frozen_string_literal:true

# From this migration, we split the user's profile into multiple tables:
# InvoicingProfile is intended to keep invoicing data about the user after his account was deleted
class MigrateProfileToInvoicingProfile < ActiveRecord::Migration[4.2]
  def up
    User.all.each do |u|
      p = u.profile
      Rails.logger.warn "User #{u.id} has no profile" and next unless p

      ip = InvoicingProfile.create!(
        user: u,
        first_name: p.first_name,
        last_name: p.last_name,
        email: u.email
      )
      Address.find_by(placeable_id: p.id, placeable_type: 'Profile')&.update(
        placeable: ip
      )
      Organization.find_by(profile_id: p.id)&.update(
        invoicing_profile_id: ip.id
      )
    end
  end

  def down
    InvoicingProfile.all.each do |ip|
      profile = ip.user.profile
      profile.update(
        first_name: ip.first_name,
        last_name: ip.last_name
      )
      Address.find_by(placeable_id: ip.id, placeable_type: 'InvoicingProfile')&.update(
        placeable: profile
      )
      Organization.find_by(invoicing_profile_id: ip.id)&.update(
        profile_id: profile.id
      )
    end
  end
end
