class MigrateProfileToInvoicingProfile < ActiveRecord::Migration
  def up
    Profile.all.each do |p|
      InvoicingProfile.create!(
        user: p.user,
        first_name: p.first_name,
        last_name: p.last_name,
        address: p.address,
        organization: p.organization
      )
    end
  end
end
