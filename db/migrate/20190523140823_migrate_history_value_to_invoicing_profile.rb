class MigrateHistoryValueToInvoicingProfile < ActiveRecord::Migration
  def up
    HistoryValue.all.each do |hv|
      user = User.find_by(id: hv.user_id)
      hv.update_attributes(
        invoicing_profile_id: user&.invoicing_profile&.id
      )
    end
  end

  def down
    HistoryValue.all.each do |hv|
      invoicing_profile = User.find_by(id: hv.invoicing_profile_id)
      hv.update_attributes(
        user_id: invoicing_profile&.user_id
      )
    end
  end
end
