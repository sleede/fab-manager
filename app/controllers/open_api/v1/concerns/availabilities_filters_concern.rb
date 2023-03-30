# frozen_string_literal: true

# Filter the list of availabilities by the given parameters
module OpenAPI::V1::Concerns::AvailabilitiesFiltersConcern
  extend ActiveSupport::Concern

  included do
    # @param availabilities [ActiveRecord::Relation<Availability>]
    # @param filters [ActionController::Parameters]
    def filter_by_id(availabilities, filters)
      return availabilities if filters[:id].blank?

      availabilities.where(id: may_array(filters[:id]))
    end

    # @param availabilities [ActiveRecord::Relation<Availability>]
    # @param filters [ActionController::Parameters]
    def filter_by_after(availabilities, filters)
      return availabilities if filters[:after].blank?

      availabilities.where('availabilities.start_at >= ?', Time.zone.parse(filters[:after]))
    end

    # @param availabilities [ActiveRecord::Relation<Availability>]
    # @param filters [ActionController::Parameters]
    def filter_by_before(availabilities, filters)
      return availabilities if filters[:before].blank?

      availabilities.where('availabilities.end_at <= ?', Time.zone.parse(filters[:before]))
    end

    # @param availabilities [ActiveRecord::Relation<Availability>]
    # @param filters [ActionController::Parameters]
    def filter_by_available_type(availabilities, filters)
      return availabilities if filters[:available_type].blank?

      availabilities.where(available_type: format_type(filters[:available_type]))
    end

    # @param availabilities [ActiveRecord::Relation<Availability>]
    # @param filters [ActionController::Parameters]
    def filter_by_available_id(availabilities, filters)
      return availabilities if filters[:available_id].blank? || filters[:available_type].blank?

      join_table = join_table(filters)
      availabilities.joins(join_table).where(join_table => { where_clause(filters) => may_array(filters[:available_id]) })
    end

    # @param type [ActionController::Parameters]
    # @return [String]
    def format_type(type)
      types = {
        'Machine' => 'machines',
        'Space' => 'space',
        'Training' => 'training',
        'Event' => 'event'
      }
      types[type]
    end

    # @param filters [ActionController::Parameters]
    # @return [Symbol]
    def join_table(filters)
      tables = {
        'Machine' => :machines_availabilities,
        'Space' => :spaces_availabilities,
        'Training' => :trainings_availabilities,
        'Event' => :event
      }
      tables[filters[:available_type]]
    end

    # @param filters [ActionController::Parameters]
    # @return [Symbol]
    def where_clause(filters)
      clauses = {
        'Machine' => :machine_id,
        'Space' => :space_id,
        'Training' => :training_id,
        'Event' => :id
      }
      clauses[filters[:available_type]]
    end
  end
end
