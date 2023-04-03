# frozen_string_literal:true

# HistoryValue must be attached to InvoicingProfile because we want to be able to blame who was responsible for a change in accounting settings
class MigrateHistoryValueToInvoicingProfile < ActiveRecord::Migration[4.2]
  def up
    HistoryValue.all.each do |hv|
      user = User.find_by(id: hv.user_id)
      hv.update(
        invoicing_profile_id: user&.invoicing_profile&.id
      )
    end
  end

  def down
    HistoryValue.all.each do |hv|
      invoicing_profile = User.find_by(id: hv.invoicing_profile_id)
      hv.update(
        user_id: invoicing_profile&.user_id
      )
    end
  end
end
