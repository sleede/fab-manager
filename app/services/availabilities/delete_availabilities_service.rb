# frozen_string_literal: true

# Provides helper methods to delete an Availability with multiple occurrences
class Availabilities::DeleteAvailabilitiesService
  def delete(availability_id, mode = 'single')

    results = []
    availability = Availability.find(availability_id)
    availabilities = case mode
                     when 'single'
                       [availability]
                     when 'next'
                       Availability.where(
                         'start_at >= ? AND occurrence_id = ? AND is_recurrent = true',
                         availability.start_at,
                         availability.occurrence_id
                       )
                     when 'all'
                       Availability.where(
                         'occurrence_id = ? AND is_recurrent = true',
                         availability.occurrence_id
                       )
                     else
                       []
                     end

    availabilities.each do |a|
      # here we use double negation because safe_destroy can return either a boolean (false) or an Availability (in case of delete success)
      results.push status: !!a.safe_destroy, availability: a # rubocop:disable Style/DoubleNegation
    end
    results
  end
end
