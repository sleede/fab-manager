# frozen_string_literal: true

# Type-dependant aata mapping functions for SSO authentications (through OmniAuth)
module OmniAuth::DataMapping::Base
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength
  included do
    def local_sym(mapping)
      "#{mapping.local_model}.#{mapping.local_field}".to_sym
    end

    def map_transformation(transformation, raw_data)
      value = nil
      transformation['mapping']&.each do |m|
        if m['from'] == raw_data
          value = m['to']
          break
        end
      end
      # if no transformation had set any value, return the raw value
      value || raw_data
    end

    def map_boolean(transformation, raw_data)
      return false if raw_data == transformation['false_value']

      true if raw_data == transformation['true_value']
    end

    def map_date(transformation, raw_data)
      case transformation['format']
      when 'iso8601'
        Time.zone.iso8601(raw_data)
      when 'rfc2822'
        Time.rfc2822(raw_data).in_time_zone
      when 'rfc3339'
        Time.rfc3339(raw_data).in_time_zone
      when 'timestamp-s'
        Time.zone.strptime(raw_data, '%s')
      when 'timestamp-ms'
        Time.zone.strptime(raw_data, '%Q')
      else
        Time.zone.parse(raw_data)
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
end
