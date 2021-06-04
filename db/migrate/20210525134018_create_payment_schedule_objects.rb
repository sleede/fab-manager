# frozen_string_literal: true

# Following the scheme of the previous migration (20210521085710_add_object_to_invoice_item.rb)
# we'll save the bought objects associated to a payment schedule into this data table.
class CreatePaymentScheduleObjects < ActiveRecord::Migration[5.2]
  def up
    create_table :payment_schedule_objects do |t|
      t.references :object, polymorphic: true
      t.belongs_to :payment_schedule, foreign_key: true
      t.boolean :main
      t.string :footprint

      t.timestamps
    end

    # PaymentSchedules were not in archives until now, so there's no need to regenerate the archives

    # migrate data
    PaymentSchedule.all.each do |payment_schedule|
      PaymentScheduleObject.create!(
        payment_schedule: payment_schedule,
        object_id: payment_schedule.scheduled_id,
        object_type: payment_schedule.scheduled_type,
        main: true
      )
    end
    PaymentSchedule.where(scheduled_type: 'Reservation').each do |payment_schedule|
      PaymentScheduleObject.create!(
        payment_schedule: payment_schedule,
        object_id: payment_schedule.payment_schedule_items.first.details['subscription_id'],
        object_type: 'Subscription'
      )
    end

    execute %(
        UPDATE payment_schedules_items
        SET payment_method = 'card'
        WHERE payment_method = 'stripe'
    )

    remove_column :payment_schedules, :scheduled_id
    remove_column :payment_schedules, :scheduled_type
    PaymentScheduleItem.update_all("details = details - 'subscription_id'")

    # chain records
    puts 'Chaining all record. This may take a while...'
    PaymentScheduleItem.order(:id).all.each(&:chain_record)
    PaymentSchedule.order(:id).all.each(&:chain_record)
  end

  def down
    add_column :payment_schedules, :scheduled_id, :integer
    add_column :payment_schedules, :scheduled_type, :string

    # migrate data
    PaymentScheduleObject.where(main: true).each do |pso|
      execute %(
        UPDATE payment_schedules
        SET scheduled_id = #{pso.object_id},
            scheduled_type = '#{pso.object_type}'
        WHERE id = #{pso.payment_schedule.id}
      )
    end
    PaymentScheduleObject.where(object_type: 'Subscription').each do |pso|
      pso.payment_schedule.payment_schedule_items.each do |psi|
        psi.details['subscription_id'] = pso.object_id
        psi.save(validate: false)
      end
    end

    execute %(
        UPDATE payment_schedules_items
        SET payment_method = 'stripe'
        WHERE payment_method = 'card'
    )

    drop_table :payment_schedule_objects

    # chain records
    puts 'Chaining all record. This may take a while...'
    PaymentScheduleItem.order(:id).all.each(&:chain_record)
    PaymentSchedule.order(:id).all.each(&:chain_record)
  end
end
