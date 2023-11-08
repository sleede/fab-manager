class FixPlanStatisticSubTypes < ActiveRecord::Migration[7.0]
  def up
    StatisticSubType.joins(statistic_types: :statistic_index).where(statistic_indices: { es_type_key: "subscription" }, label: nil).each do |statistic_sub_type|
      plan = Plan.find_by(slug: statistic_sub_type.key)
      if plan
        statistic_sub_type.update_column(:label, plan.name)
      end
    end
  end

  def down
  end
end
