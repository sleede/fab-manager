# frozen_string_literal: true

# Normalize ES9 totals and physical indices at the Rails/XLSX compatibility edge.
class SearchIndex::Result
  attr_reader :legacy_response

  def initialize(response)
    response = response.body if response.respond_to?(:body)
    if response['timed_out'] || response.dig('_shards', 'failed').to_i.positive?
      raise SearchIndex::IncompleteRead, 'Elasticsearch returned a partial result'
    end

    @legacy_response = normalize(response)
  end

  def total
    { 'value' => legacy_response.fetch('hits').fetch('total'), 'relation' => 'eq' }
  end

  def hits
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

  private

  def normalize(value)
    case value
    when Array
      value.map { |entry| normalize(entry) }
    when Hash
      return normalize_hit(value) if value.key?('_index') && value.key?('_id')

      value.to_h do |key, entry|
        if key == 'total' && entry.is_a?(Hash) && entry.key?('relation')
          raise SearchIndex::IncompleteRead, 'Exact total was not returned' unless entry['relation'] == 'eq'

          [key, entry.fetch('value')]
        else
          [key, normalize(entry)]
        end
      end
    else
      value
    end
  end

  def normalize_hit(hit)
    family = SearchIndex.family_from_index(hit.fetch('_index'))
    hit.merge('_index' => family == 'availabilities' ? 'fablab' : 'stats', '_type' => family).tap do |result|
      result['_source'] = hit['_source'].except('__fm') if hit['_source']
    end
  end
end
