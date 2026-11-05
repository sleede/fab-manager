# frozen_string_literal: true

# One physical index per legacy family; aliases are the application contract.
class SearchIndex::Schema
  VERSION = 1
  TEXT_FIELDS = %w[gender group groupName coupon state status].freeze

  class << self
    def physical(family)
      "#{SearchIndex.target(family).fetch(:index)}-v#{VERSION}"
    end

    def definition(family)
      { settings: { number_of_shards: 1, number_of_replicas: 0, 'index.mapping.total_fields.limit' => 1000 },
        mappings: { _meta: { fab_manager_schema: VERSION, family: family }, dynamic: 'true',
                    date_detection: false, dynamic_templates: [{ strings: { match_mapping_type: 'string', mapping: text_field } }],
                    properties: properties(family) } }.deep_stringify_keys
    end

    def properties(family)
      fields = { '__fm' => { dynamic: 'strict', properties: { uid: { type: 'keyword' } } } }
      return fields.merge(availability_properties) if family == 'availabilities'

      %w[type subType name ageRange eventTheme].each { |name| fields[name] = { type: 'keyword' } }
      TEXT_FIELDS.each { |name| fields[name] = text_field }
      %w[date created_at updated_at eventDate trainingDate].each { |name| fields[name] = { type: 'date' } }
      %w[userId age reservationId reservationContextId eventId machineId spaceId trainingId planId
         subscriptionId invoiceItemId orderId projectId users].each { |name| fields[name] = { type: 'long' } }
      %w[stat ca].each { |name| fields[name] = { type: 'float' } }
      %w[machineDates spaceDates].each { |name| fields[name] = { properties: { name: { type: 'date' } } } }
      %w[licence themes components machines projectUserNames products categories].each do |name|
        fields[name] = { properties: { id: { type: 'long' }, name: text_field } }
      end
      fields
    end

    def initialize!(client)
      raise SearchIndex::SchemaConflict, 'This schema requires Elasticsearch 9' unless client.info.dig('version', 'number').start_with?('9.')

      %w[stats fablab].each do |legacy|
        raise SearchIndex::SchemaConflict, 'Legacy indices require a separate data migration' if client.indices.exists?(index: legacy)
      end
      # Inspect every existing target before creating anything; never overwrite an unknown alias or mapping.
      SearchIndex::FAMILIES.each { |family| validate_existing!(client, family) }
      validate_all_alias!(client)
      SearchIndex::FAMILIES.each do |family|
        index = physical(family)
        next if client.indices.exists?(index: index)

        client.indices.create(index: index, body: definition(family))
      end
      actions = SearchIndex::FAMILIES.flat_map do |family|
        entry = { add: { index: physical(family), alias: SearchIndex.target(family).fetch(:index), is_write_index: true } }
        family == 'availabilities' ? [entry] : [entry, { add: { index: physical(family), alias: 'fm-stats-all' } }]
      end
      client.indices.update_aliases(body: { actions: actions })
    end

    def validate!(client)
      SearchIndex::FAMILIES.each do |family|
        unless client.indices.exists?(index: physical(family)) && client.indices.exists?(index: SearchIndex.target(family).fetch(:index))
          raise SearchIndex::SchemaConflict, "Missing initialized index/alias: #{family}"
        end

        validate_existing!(client, family)
      end
      validate_all_alias!(client)
      actual = client.indices.get_alias(name: 'fm-stats-all').body.keys.sort
      expected = SearchIndex::STAT_FAMILIES.map { |family| physical(family) }.sort
      raise SearchIndex::SchemaConflict, 'Incomplete statistics alias' unless actual == expected

      true
    end

    def keyword_field(field)
      name = field.to_s
      TEXT_FIELDS.include?(name) || (name.end_with?('.name') && !name.match?(/\A(machineDates|spaceDates)\./)) ? "#{name}.keyword" : name
    end

    private

    def text_field
      { type: 'text', fields: { keyword: { type: 'keyword', ignore_above: 256 } } }
    end

    def availability_properties
      fields = { 'available_type' => { type: 'text', analyzer: 'simple', fields: { keyword: { type: 'keyword' } } },
                 'subType' => { type: 'keyword' } }
      %w[start_at end_at end_date date created_at updated_at].each { |name| fields[name] = { type: 'date' } }
      %w[id nb_total_places slot_duration occurrence_id nb_periods].each { |name| fields[name] = { type: 'long' } }
      %w[hours_duration bookable_hours].each { |name| fields[name] = { type: 'float' } }
      %w[destroying lock is_recurrent].each { |name| fields[name] = { type: 'boolean' } }
      fields
    end

    def validate_existing!(client, family)
      index = physical(family)
      alias_name = SearchIndex.target(family).fetch(:index)
      if client.indices.exists?(index: alias_name)
        aliases = client.indices.get_alias(name: alias_name).body
        raise SearchIndex::SchemaConflict, "Unexpected alias target: #{alias_name}" unless aliases.keys == [index]
        unless aliases.fetch(index).fetch('aliases').fetch(alias_name) == { 'is_write_index' => true }
          raise SearchIndex::SchemaConflict, "Unexpected alias configuration: #{alias_name}"
        end
      end
      return unless client.indices.exists?(index: index)

      actual = client.indices.get_mapping(index: index).body.fetch(index).fetch('mappings')
      expected = definition(family).fetch('mappings')
      raise SearchIndex::SchemaConflict, "Existing mapping requires review: #{index}" unless contains?(actual, expected)
    end

    def validate_all_alias!(client)
      return unless client.indices.exists?(index: 'fm-stats-all')

      aliases = client.indices.get_alias(name: 'fm-stats-all').body
      indices = aliases.keys
      expected = SearchIndex::STAT_FAMILIES.map { |family| physical(family) }
      raise SearchIndex::SchemaConflict, 'Unknown member of fm-stats-all' if (indices - expected).any?

      unfiltered = aliases.values.all? { |value| value.dig('aliases', 'fm-stats-all') == {} }
      raise SearchIndex::SchemaConflict, 'Filtered statistics alias requires review' unless unfiltered
    end

    def contains?(actual, expected)
      return actual == expected unless expected.is_a?(Hash)
      return false unless actual.is_a?(Hash)

      expected.all? do |key, value|
        # Existing ES5 sites can use float or double. Migration retains their numeric semantics.
        key == 'type' && value == 'float' ? %w[float double long integer short byte].include?(actual[key]) : contains?(actual[key], value)
      end
    end
  end
end
