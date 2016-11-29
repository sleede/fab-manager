class MigrateEventReducedAmountToPriceCategory < ActiveRecord::Migration
  def up
    pc = PriceCategory.new(
        name: I18n.t('price_category.reduced_fare'),
        conditions: I18n.t('price_category.reduced_fare_if_you_are_under_25_student_or_unemployed')
    )
    pc.save!

    Event.where.not(reduced_amount: nil).each do |event|
      unless event.reduced_amount == 0 and event.amount == 0
        epc = EventPriceCategory.new(
            event: event,
            price_category: pc,
            amount: event.reduced_amount
        )
        epc.save!

        Reservation.where(reservable_type: 'Event', reservable_id: event.id).where('nb_reserve_reduced_places > 0').each do |r|
          t = Ticket.new(
              reservation: r,
              event_price_category: epc,
              booked: r.nb_reserve_reduced_places
          )
          t.save!
        end
      end
    end
  end

  def down
    pc = PriceCategory.find_by(name: I18n.t('price_category.reduced_fare'))
    EventPriceCategory.where(price_category_id: pc.id).each do |epc|
      epc.event.update_column(:reduced_amount, epc.amount)

      Reservation.where(reservable_type: 'Event', reservable_id: epc.event.id).each do |r|
        r.tickets.each do |t|
          if t.event_price_category_id == epc.id
            r.update_column(:nb_reserve_reduced_places, t.booked)
            t.destroy!
            break
          end
        end
      end
      epc.destroy!
    end

    pc.destroy!
  end
end
