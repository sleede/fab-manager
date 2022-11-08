# frozen_string_literal: true

# Generate statistics indicators about reservations
class Statistics::Builders::ReservationsBuilderService
  include Statistics::Concerns::HelpersConcern

  class << self
    def build(options = default_options)
      # machine/space/training list
      %w[machine space training event].each do |category|
        Statistics::FetcherService.send("reservations_#{category}_list", options).each do |r|
          %w[booking hour].each do |type|
            stat = "Stats::#{category.capitalize}"
                   .constantize
                   .new({ date: format_date(r[:date]),
                          type: type,
                          subType: r["#{category}_type".to_sym],
                          ca: r[:ca],
                          name: r["#{category}_name".to_sym],
                          reservationId: r[:reservation_id] }.merge(user_info_stat(r)))
            stat[:stat] = (type == 'booking' ? 1 : r[:nb_hours])
            stat["#{category}Id".to_sym] = r["#{category}_id".to_sym]

            if category == 'event'
              stat[:eventDate] = r[:event_date]
              stat[:eventTheme] = r[:event_theme]
              stat[:ageRange] = r[:age_range]
            end

            stat.save
          end
        end
      end
    end
  end
end
