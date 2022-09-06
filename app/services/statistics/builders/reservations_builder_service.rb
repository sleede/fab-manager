# frozen_string_literal: true

# Generate statistics indicators about reservations
class Statistics::Builders::ReservationsBuilderService
  include Statistics::Concerns::HelpersConcern

  class << self
    def build(options = default_options)
      # machine/space/training list
      %w[machine space training].each do |category|
        Statistics::FetcherService.send("reservations_#{category}_list", options).each do |r|
          %w[booking hour].each do |type|
            stat = Stats::Machine.new({ date: format_date(r[:date]),
                                        type: type,
                                        subType: r["#{category}_type".to_sym],
                                        ca: r[:ca],
                                        machineId: r["#{category}_id".to_sym],
                                        name: r["#{category}_name".to_sym],
                                        reservationId: r[:reservation_id] }.merge(user_info_stat(r)))
            stat.stat = (type == 'booking' ? 1 : r[:nb_hours])
            stat.save
          end
        end
      end

      # event list
      Statistics::FetcherService.reservations_event_list(options).each do |r|
        %w[booking hour].each do |type|
          stat = Stats::Event.new({ date: format_date(r[:date]),
                                    type: type,
                                    subType: r[:event_type],
                                    ca: r[:ca],
                                    eventId: r[:event_id],
                                    name: r[:event_name],
                                    eventDate: r[:event_date],
                                    reservationId: r[:reservation_id],
                                    eventTheme: r[:event_theme],
                                    ageRange: r[:age_range] }.merge(user_info_stat(r)))
          stat.stat = (type == 'booking' ? r[:nb_places] : r[:nb_hours])
          stat.save
        end
      end
    end
  end
end
