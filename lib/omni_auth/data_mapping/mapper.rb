# frozen_string_literal: true

module OmniAuth::DataMapping
  # Build the data mapping for the given provider
  module Mapper
    extend ActiveSupport::Concern

    included do
      require 'sso_logger'
      require_relative 'base'
      include OmniAuth::DataMapping::Base

      def mapped_info(mappings, raw_info)
        logger = SsoLogger.new
        @info ||= {}

        logger.debug "[mapped_info] @info = #{@info.to_json}"

        unless @info.size.positive?
          mappings.each do |mapping|

            raw_data = ::JsonPath.new(mapping.api_field).on(raw_info[mapping.api_endpoint.to_sym]).first
            logger.debug "@parsed_info[#{local_sym(mapping)}] mapped from #{raw_data}"
            @info[local_sym(mapping)] = if mapping.transformation
                                          case mapping.transformation['type']
                                          when 'integer'
                                            map_transformation(mapping.transformation, raw_data)
                                          when 'boolean'
                                            map_boolean(mapping.transformation, raw_data)
                                          when 'date'
                                            map_date(mapping.transformation, raw_data)
                                          when 'string'
                                            map_transformation(mapping.transformation, raw_data)
                                          else
                                            # other unsupported transformation
                                            raw_data
                                          end
                                        else
                                          raw_data
                                        end
          end
        end
        @info
      end
    end
  end
end
