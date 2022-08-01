# frozen_string_literal: true

# Data mapping functions for SSO authentications (through OmniAuth)
module OmniAuth::DataMapping
  # Type-dependant mapping functions
  module Base
    extend ActiveSupport::Concern

    included do
      def local_sym(mapping)
        (mapping.local_model + '.' + mapping.local_field).to_sym
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
          DateTime.iso8601(raw_data)
        when 'rfc2822'
          DateTime.rfc2822(raw_data)
        when 'rfc3339'
          DateTime.rfc3339(raw_data)
        when 'timestamp-s'
          DateTime.strptime(raw_data, '%s')
        when 'timestamp-ms'
          DateTime.strptime(raw_data, '%Q')
        else
          DateTime.parse(raw_data)
        end
      end
    end
  end
end
