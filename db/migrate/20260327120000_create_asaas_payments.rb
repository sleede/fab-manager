# frozen_string_literal: true

# Creates the Asaas payments table.
class CreateAsaasPayments < ActiveRecord::Migration[5.2]
  def change
    create_table :asaas_payments do |t|
      t.string :token, null: false
      t.string :status, null: false
      t.string :asaas_customer_id
      t.string :asaas_payment_id
      t.string :event_name
      t.string :item_type
      t.bigint :item_id
      t.string :result_type
      t.bigint :result_id
      t.references :operator, foreign_key: { to_table: :users }, null: false
      t.references :customer, foreign_key: { to_table: :users }, null: false
      t.text :pix_payload
      t.text :pix_encoded_image
      t.datetime :pix_expiration_at
      t.integer :amount, null: false, default: 0
      t.jsonb :cart_items
      t.jsonb :payment_data
      t.datetime :paid_at
      t.datetime :finalized_at

      t.timestamps
    end

    add_index :asaas_payments, :token, unique: true
    add_index :asaas_payments, :asaas_payment_id, unique: true
    add_index :asaas_payments, %i[item_type item_id]
    add_index :asaas_payments, %i[result_type result_id]
  end
end
