# frozen_string_literal: true

require 'set'
require 'securerandom'

# Application operations on one Elasticsearch 9 backend. Rails remains the access boundary.
class SearchIndex
  STAT_FAMILIES = %w[account event machine project subscription training user space order].freeze
  FAMILIES = (STAT_FAMILIES + ['availabilities']).freeze
  TARGETS = FAMILIES.index_with { |family| { index: family == 'availabilities' ? 'fm-availabilities' : "fm-stats-#{family}" }.freeze }.freeze
  SEARCH_OPTIONS = %i[scroll size from search_type].freeze

  class IncompleteRead < StandardError; end
  class UnsupportedQuery < ArgumentError; end
  class SchemaConflict < StandardError; end

  # Preserve every item result so callers can distinguish partial success from failure.
  class BulkFailure < StandardError
    attr_reader :items

    def initialize(items)
      @items = items
      super('Elasticsearch bulk contains failed or missing items; inspect items before retrying')
    end
  end

  class << self
    def target(family)
      TARGETS.fetch(family.to_s) { raise ArgumentError, "Unknown search family: #{family}" }
    end

    def family_for(index:, type:)
      return type if STAT_FAMILIES.include?(type) && index == 'stats'
      return type if type == 'availabilities' && index == 'fablab'

      raise ArgumentError, "Unknown search target: #{index}/#{type}"
    end

    def family_from_index(index)
      FAMILIES.find { |family| index == Schema.physical(family) } || raise(SchemaConflict, "Unknown search index: #{index}")
    end

    def search(family:, query:, **options)
      raise UnsupportedQuery, 'Unsupported search parameter' if (options.keys - SEARCH_OPTIONS).any?

      Result.new(request(:search, **options, index: read_index(family), body: Query.build(query)))
    end

    def next_page(cursor:, keep_alive: '30s')
      Result.new(request(:scroll, body: { scroll: keep_alive, scroll_id: cursor }))
    end

    def close_cursor(cursor:)
      request(:clear_scroll, body: { scroll_id: [cursor] }) if cursor
    end

    def each_page(family:, query:, page_size: 1000)
      return enum_for(__method__, family: family, query: query, page_size: page_size) unless block_given?

      cursor = nil
      count = 0
      seen = Set.new
      body = Query.build(query).merge('size' => page_size)
      response = request(:search, index: read_index(family), body: body, scroll: '30s')
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

        response = request(:scroll, body: { scroll: '30s', scroll_id: cursor })
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
      build_stat(family: family, attributes: attributes).tap { |record| save_stat(record) }
    end

    def save_stat(record)
      return false unless record.valid?

      record.created_at ||= Time.now.utc
      record.updated_at = Time.now.utc
      id = record.id || SecureRandom.uuid
      index_document(family: record.class.family, id: id, source: record.as_json)
      record.id = id
      true
    end

    def index_document(family:, id:, source:)
      request(:index, **target(family), id: id.to_s, require_alias: true, body: document(family, id, source))
    end

    def index_availability(record:)
      index_document(family: 'availabilities', id: record.id, source: JSON.parse(record.as_indexed_json))
    end

    def update_stat(family:, id:, changes:)
      raise ArgumentError, 'Reserved metadata' if changes.stringify_keys.key?('__fm')

      request(:update, **target(family), id: id.to_s, require_alias: true, body: { doc: changes.merge(updated_at: Time.now.utc) })
    end

    def bulk_index(family:, documents:)
      body = documents.flat_map do |entry|
        [{ index: { _index: target(family).fetch(:index), _id: entry.fetch(:id).to_s } },
         document(family, entry.fetch(:id), entry.fetch(:source))]
      end
      result = request(:bulk, require_alias: true, body: body)
      items = result.fetch('items')
      failed = items.any? { |item| item.values.any? { |status| status['error'] || !status.fetch('status').between?(200, 299) } }
      raise BulkFailure, items if failed || result['errors'] || items.length != documents.length

      result
    end

    def delete(family:, id:)
      request(:delete, **target(family), id: id.to_s)
    end

    def delete_by_query(family:, query:, **options)
      result = request(:delete_by_query, **options, **target(family), body: Query.build({ query: query }).except('track_total_hits'))
      conflicts = options[:conflicts].to_s != 'proceed' && result['version_conflicts'].to_i.positive?
      raise IncompleteRead, 'Incomplete Elasticsearch deletion' if result['timed_out'] || result.fetch('failures', []).any? || conflicts

      result
    end

    def refresh(family:)
      client.indices.refresh(index: read_index(family))
    end

    def healthy?
      !!client.cluster.health
    rescue Elastic::Transport::Transport::Error, Faraday::Error, Connection::Unavailable
      false
    end

    def initialize_schema!
      Schema.initialize!(client)
    end

    private

    def read_index(family)
      family.to_s == 'all_stats' ? 'fm-stats-all' : target(family).fetch(:index)
    end

    def client
      Connection.client
    end

    def request(operation, **arguments)
      ElasticsearchMigrationGuard.write!(client) if %i[index update bulk delete delete_by_query].include?(operation)
      ActiveSupport::Notifications.instrument('request.elasticsearch', operation: operation, index: arguments[:index]) do
        response = client.public_send(operation, **arguments)
        response.respond_to?(:body) ? response.body : response
      end
    end

    def document(family, id, source)
      raise ArgumentError, 'An opaque nonempty ID is required' if id.nil? || id.to_s.empty?
      raise ArgumentError, 'Reserved metadata' if source.stringify_keys.key?('__fm')

      source.merge('__fm' => { 'uid' => "#{family}##{id}" })
    end
  end
end
