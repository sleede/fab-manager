class MigrateUserToInvoicingProfile < ActiveRecord::Migration
  def up
    # first, check the footprints
    puts 'Checking all invoices footprints. This may take a while...'
    Invoice.where.not(footprint: nil).order(:created_at).all.each do |i|
      raise "Invalid footprint for invoice #{i.id}" unless i.check_footprint
    end
    # if everything is ok, proceed with migration
    Invoice.order(:created_at).all.each do |i|
      i.update_column('invoicing_profile_id', i.user.invoicing_profile.id)
      i.update_column('user_id', nil)
      i.chain_record
    end
  end

  def down
    Invoice.order(:created_at).all.each do |i|
      i.update_column('user_id', i.invoicing_profile.user_id)
      i.update_column('invoicing_profile_id', nil)
      i.chain_record
    end
  end
end
