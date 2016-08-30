class MigrateEventReducedAmountToPriceCategory < ActiveRecord::Migration
  def change
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
end
