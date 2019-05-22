class MigrateProfileToInvoicingProfile < ActiveRecord::Migration
  def up
    User.all.each do |u|
      p = u.profile
      puts "WARNING: User #{u.id} has no profile" and next unless p

      ip = InvoicingProfile.create!(
        user: u,
        first_name: p.first_name,
        last_name: p.last_name
      )
      p.address&.update_attributes(
        placeable: ip
      )
      p.organization&.update_attributes(
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
      ip.address&.update_attributes(
        placeable: profile
      )
      ip.organization&.update_attributes(
        profile_id: profile.id
      )
    end
  end
end
