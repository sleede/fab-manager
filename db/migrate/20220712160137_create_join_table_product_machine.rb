class CreateJoinTableProductMachine < ActiveRecord::Migration[5.2]
  def change
    create_join_table :products, :machines do |t|
      # t.index [:product_id, :machine_id]
      # t.index [:machine_id, :product_id]
    end
  end
end
