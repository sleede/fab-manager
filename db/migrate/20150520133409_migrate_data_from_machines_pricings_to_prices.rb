class MigrateDataFromMachinesPricingsToPrices < ActiveRecord::Migration
  def up
    insert <<-SQL
      DELETE FROM machines_pricings WHERE machine_id NOT IN ( select distinct machines.id from machines )
    SQL

    machines_pricings = select_all("SELECT * FROM machines_pricings")
    machines_pricings.each do |m_pricing|
      time = "'#{Time.now.to_s(:db)}'"

      plan_year = select_one("SELECT id FROM plans where plans.group_id = #{m_pricing['group_id']} and plans.interval = 'year'")
      insert <<-SQL
        INSERT INTO prices (group_id, plan_id, priceable_id, priceable_type, amount, created_at, updated_at)
        VALUES (#{m_pricing['group_id']}, #{plan_year['id']}, #{m_pricing['machine_id']}, 'Machine', #{m_pricing['year_amount']}, #{time}, #{time})
      SQL

      plan_month = select_one("SELECT id FROM plans where plans.group_id = #{m_pricing['group_id']} and plans.interval = 'month'")
      insert <<-SQL
        INSERT INTO prices (group_id, plan_id, priceable_id, priceable_type, amount, created_at, updated_at)
        VALUES (#{m_pricing['group_id']}, #{plan_month['id']}, #{m_pricing['machine_id']}, 'Machine', #{m_pricing['month_amount']}, #{time}, #{time})
      SQL

      insert <<-SQL
        INSERT INTO prices (group_id, plan_id, priceable_id, priceable_type, amount, created_at, updated_at)
        VALUES (#{m_pricing['group_id']}, NULL, #{m_pricing['machine_id']}, 'Machine', #{m_pricing['not_subscribe_amount']}, #{time}, #{time})
      SQL
    end
  end

  def down
    insert <<-SQL
      DELETE FROM prices
    SQL
  end
end
