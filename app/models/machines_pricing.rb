##DEPRECATED, this class is not used anymore from the migration to the Pricing model
##TODO remove in future update, in conjunction with the following migrations:
#   - 20140606133116_create_machines_pricings.rb
#   - 20150520133409_migrate_data_from_machines_pricings_to_prices.rb
#   - 20150603133050_drop_machines_pricings.rb
class MachinesPricing < ActiveRecord::Base
  belongs_to :machine
  belongs_to :group
end
