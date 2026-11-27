# frozen_string_literal: true

require 'set'

# The Elasticsearch 5.6 operations used by availability and statistics consumers.
# Keep legacy model serialization here until the persistence models are detached.
class SearchIndex
  STAT_FAMILIES = %w[account event machine project subscription training user space order].freeze
  TARGETS = STAT_FAMILIES.index_with { |family| { index: 'stats', type: family }.freeze }
                         .merge('availabilities' => { index: 'fablab', type: 'availabilities' }.freeze).freeze

  class IncompleteRead < StandardError; end

  # Internal contract; legacy_response is the compatibility edge for AngularJS/XLSX.
  class Result
    attr_reader :legacy_response

    def initialize(response)
      if response['timed_out'] || response.dig('_shards', 'failed').to_i.positive?
        raise IncompleteRead, 'Elasticsearch returned a partial result'
      end

      @legacy_response = response
    end

    def total
      { 'value' => legacy_response.fetch('hits').fetch('total'), 'relation' => 'eq' }
    end

    def hits
      # The catalogue restricts request targets; a read over all_stats keeps any stored type, as the XLSX templates do.
      legacy_response.fetch('hits').fetch('hits').map do |hit|
        { 'family' => hit.fetch('_type'), 'id' => hit.fetch('_id').to_s, '_source' => hit.fetch('_source') }
          .tap { |result| result['routing'] = hit['_routing'] if hit.key?('_routing') }
      end
    end

    def to_h
      { 'total' => total, 'hits' => hits, 'aggregations' => legacy_response['aggregations'] }
    end

    def cursor
      legacy_response['_scroll_id']
    end
  end

  class << self
    def target(family)
      TARGETS.fetch(family.to_s) { raise ArgumentError, "Unknown search family: #{family}" }
    end

    def family_for(index:, type:)
      TARGETS.key(index: index, type: type) || raise(ArgumentError, "Unknown search target: #{index}/#{type}")
    end

    def search(family:, query:, **options)
      Result.new(client.search(**options, **search_target(family), body: query))
    end

    def next_page(cursor:, keep_alive: '30s')
      Result.new(client.scroll(scroll: keep_alive, scroll_id: cursor))
    end

    def close_cursor(cursor:)
      client.clear_scroll(scroll_id: cursor) if cursor
    end

    # Terminate on an empty page, check the exact total, and release even on errors.
    def each_page(family:, query:, page_size: 1000)
      return enum_for(__method__, family: family, query: query, page_size: page_size) unless block_given?

      cursor = nil
      count = 0
      seen = Set.new
      response = client.search(**search_target(family), body: query, size: page_size, scroll: '30s')
      cursor = response['_scroll_id']
      page = Result.new(response)
      total = page.total.fetch('value')
      loop do
        cursor = page.cursor || cursor
        hits = page.hits
        if hits.empty?
          yield page if total.zero?
          break
        end

        hits.each do |hit|
          raise IncompleteRead, 'Repeated document in Elasticsearch cursor' unless seen.add?([hit['family'], hit['id']])
        end
        count += hits.length
        raise IncompleteRead, 'Cursor returned more than the exact total' if count > total

        yield page
        raise IncompleteRead, 'Missing Elasticsearch cursor' unless cursor

        # Capture the newest ID before checking the next response for shard errors.
        response = client.scroll(scroll: '30s', scroll_id: cursor)
        cursor = response['_scroll_id'] || cursor
        page = Result.new(response)
      end
      raise IncompleteRead, "Incomplete Elasticsearch cursor: #{count}/#{total}" unless count == total
    ensure
      close_cursor(cursor: cursor) if cursor
    end

    def each_hit(family:, query:, page_size: 1000, &block)
      return enum_for(__method__, family: family, query: query, page_size: page_size) unless block

      each_page(family: family, query: query, page_size: page_size) { |page| page.hits.each(&block) }
    end

    def export(family:, query:)
      result = nil
      each_page(family: family, query: query) do |page|
        if result
          result['hits']['hits'].concat(page.legacy_response['hits']['hits'])
        else
          result = page.legacy_response.deep_dup
        end
      end
      result
    end

    def build_stat(family:, attributes:)
      raise ArgumentError, "Not a statistics family: #{family}" unless STAT_FAMILIES.include?(family.to_s)

      "Stats::#{family.to_s.camelize}".constantize.new(attributes)
    end

    def create_stat(family:, attributes:)
      record = build_stat(family: family, attributes: attributes)
      record.run_callbacks(:create) { save_stat(record) }
      record
    end

    def save_stat(record)
      target(record.class.document_type)
      record.save
    end

    def update_stat(family:, id:, changes:)
      client.update(**target(family), id: id.to_s, body: { doc: changes.merge(updated_at: Time.now.utc) })
    end

    def index_availability(record:)
      client.index(**target('availabilities'), id: record.id.to_s, body: record.as_indexed_json)
    end

    def delete(family:, id:)
      client.delete(**target(family), id: id.to_s)
    end

    # Conflicts are a failure unless the caller explicitly asked Elasticsearch to proceed past them.
    def delete_by_query(family:, query:, **options)
      result = client.delete_by_query(**options, **target(family), body: { query: query })
      conflicts = options[:conflicts].to_s != 'proceed' && result['version_conflicts'].to_i.positive?
      raise IncompleteRead, 'Incomplete Elasticsearch deletion' if result['timed_out'] || result.fetch('failures', []).any? || conflicts

      result
    end

    def refresh(family:)
      client.indices.refresh(index: search_target(family).fetch(:index))
    end

    def healthy?
      !!client.cluster.health
    rescue Elasticsearch::Transport::Transport::Error, Faraday::ConnectionFailed
      false
    end

    # Only the explicit, historically destructive rebuild task calls this method.
    def rebuild_statistics!
      client.indices.delete(index: 'stats') if client.indices.exists?(index: 'stats')
      client.indices.create(index: 'stats', body: { settings: { index: { number_of_replicas: 0 } } })
      # Preserve the eight explicit legacy mappings; order is dynamically mapped in 5.6.
      (STAT_FAMILIES - ['order']).each do |family|
        client.indices.put_mapping(**target(family), body: { properties: statistics_properties })
      end
      add_event_filters
    end

    def add_event_filters
      client.indices.put_mapping(**target('event'), body: { properties: {
                                   ageRange: { type: 'string', index: 'not_analyzed' },
                                   eventTheme: { type: 'string', index: 'not_analyzed' }
                                 } })
    end

    def add_spaces_mapping
      client.indices.put_mapping(**target('space'), body: { properties: statistics_properties })
    end

    # Applying the known mapping does not delete existing documents or other types.
    def ensure_availability_mapping
      client.indices.create(index: 'fablab', body: { settings: Availability.settings.to_hash }) unless client.indices.exists?(index: 'fablab')
      client.indices.put_mapping(**target('availabilities'), body: Availability.mappings.to_hash)
    end

    private

    def search_target(family)
      family.to_s == 'all_stats' ? { index: 'stats' } : target(family)
    end

    def client
      Elasticsearch::Model.client
    end

    def statistics_properties
      { type: { type: 'string', index: 'not_analyzed' }, subType: { type: 'string', index: 'not_analyzed' },
        date: { type: 'date' }, name: { type: 'string', index: 'not_analyzed' } }
    end
  end
end
