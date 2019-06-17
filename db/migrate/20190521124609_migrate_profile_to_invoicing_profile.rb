class MigrateProfileToInvoicingProfile < ActiveRecord::Migration
  def up
    User.all.each do |u|
      p = u.profile
      puts "WARNING: User #{u.id} has no profile" and next unless p

      ip = InvoicingProfile.create!(
        user: u,
        first_name: p.first_name,
        last_name: p.last_name,
        email: u.email
      )
      Address.find_by(placeable_id: p.id, placeable_type: 'Profile')&.update_attributes(
        placeable: ip
      )
      Organization.find_by(profile_id: p.id)&.update_attributes(
        invoicing_profile_id: ip.id
      )
    end
  end

  def down
    InvoicingProfile.all.each do |ip|
      profile = ip.user.profile
      profile.update_attributes(
        first_name: ip.first_name,
        last_name: ip.last_name
      )
      Address.find_by(placeable_id: ip.id, placeable_type: 'InvoicingProfile')&.update_attributes(
        placeable: profile
      )
      Organization.find_by(invoicing_profile_id: ip.id)&.update_attributes(
        profile_id: profile.id
      )
    end
  end
end
