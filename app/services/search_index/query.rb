# frozen_string_literal: true

# Translate the legacy DSL actually emitted by statistics, graphs and stored queries.
class SearchIndex::Query
  ROOT_KEYS = %w[query aggs aggregations sort size from _source track_total_hits].freeze
  CALENDAR_INTERVALS = %w[year quarter month week day hour minute second 1y 1q 1M 1w 1d 1h 1m 1s].freeze
  AVERAGE_CART_SCRIPT = 'BigDecimal.valueOf(_value).setScale(1, RoundingMode.HALF_UP)'
  METRICS = %w[sum avg min max value_count cardinality stats extended_stats].freeze

  def self.build(query)
    new.build(query)
  end

  def build(query)
    raise SearchIndex::UnsupportedQuery, 'Search body must be an object' unless query.is_a?(Hash) || query.is_a?(String)

    body = query.is_a?(String) ? JSON.parse(query) : query.deep_stringify_keys.deep_dup
    raise SearchIndex::UnsupportedQuery, 'Search body must be an object' unless body.is_a?(Hash)
    raise SearchIndex::UnsupportedQuery, 'Unsupported search option' if (body.keys - ROOT_KEYS).any?

    body['query'] = clause(body['query']) if body['query']
    %w[aggs aggregations].each { |key| body[key] = aggregations(body[key]) if body[key] }
    body['sort'] = sort(body['sort']) if body['sort']
    body['track_total_hits'] = true
    body
  end

  private

  def clause(value)
    raise SearchIndex::UnsupportedQuery, 'Expected one query clause' unless value.is_a?(Hash) && value.size == 1

    name, parameters = value.first
    raise SearchIndex::UnsupportedQuery, 'Expected query parameters' unless parameters.is_a?(Hash)

    case name
    when 'bool'
      allowed = %w[must must_not should filter minimum_should_match boost]
      raise SearchIndex::UnsupportedQuery, 'Unsupported bool option' if (parameters.keys - allowed).any?

      parameters = parameters.to_h do |key, entries|
        [key, %w[must must_not should filter].include?(key) ? Array.wrap(entries).map { |entry| clause(entry) } : entries]
      end
    when 'terms'
      raise SearchIndex::UnsupportedQuery, 'Terms lookup is not an application query' if parameters.values.any? { |entry| entry.is_a?(Hash) }
    when 'term', 'match', 'range', 'exists', 'match_all'
      # These clauses operate on the already resolved family only.
    else
      raise SearchIndex::UnsupportedQuery, "Unsupported query clause: #{name}"
    end
    { name => parameters }
  end

  def aggregations(values)
    raise SearchIndex::UnsupportedQuery, 'Expected aggregations object' unless values.is_a?(Hash)

    values.transform_values do |definition|
      raise SearchIndex::UnsupportedQuery, 'Expected aggregation definition' unless definition.is_a?(Hash)

      definition.to_h do |kind, parameters|
        raise SearchIndex::UnsupportedQuery, 'Expected aggregation parameters' unless parameters.is_a?(Hash)

        translated = case kind
                     when 'aggs', 'aggregations' then aggregations(parameters)
                     when 'date_histogram' then histogram(parameters)
                     when 'terms' then terms(parameters)
                     when 'top_hits' then top_hits(parameters)
                     when 'filter' then clause(parameters)
                     when 'meta' then parameters
                     when *METRICS then metric(parameters)
                     else raise SearchIndex::UnsupportedQuery, "Unsupported aggregation: #{kind}"
                     end
        [kind, translated]
      end
    end
  end

  def histogram(parameters)
    result = parameters.deep_dup
    interval = result.delete('interval')
    return result unless interval

    raise SearchIndex::UnsupportedQuery, 'Ambiguous date interval' if result.key?('calendar_interval') || result.key?('fixed_interval')

    if CALENDAR_INTERVALS.include?(interval)
      result['calendar_interval'] = interval
    elsif interval.is_a?(String) && interval.match?(/\A[1-9]\d*(ms|s|m|h|d)\z/)
      result['fixed_interval'] = interval
    else
      raise SearchIndex::UnsupportedQuery, "Unsupported date interval: #{interval}"
    end
    result
  end

  def terms(parameters)
    result = metric(parameters)
    result = result.merge('field' => SearchIndex::Schema.keyword_field(result['field'])) if result['field']
    result['order'] = result['order'].transform_keys { |key| key == '_term' ? '_key' : key } if result['order'].is_a?(Hash)
    result
  end

  def metric(parameters)
    return parameters unless parameters.key?('script')

    script = parameters['script']
    source = script.is_a?(Hash) ? script['source'] : script
    unless source == AVERAGE_CART_SCRIPT && (!script.is_a?(Hash) || (script.keys - %w[source lang]).empty?)
      raise SearchIndex::UnsupportedQuery, 'Stored script needs explicit migration review'
    end

    parameters.merge('script' => { 'source' => source, 'lang' => 'painless' })
  end

  def top_hits(parameters)
    raise SearchIndex::UnsupportedQuery, 'Unsupported top_hits option' if (parameters.keys - %w[size from sort _source]).any?

    result = parameters.deep_dup
    result['sort'] = sort(result['sort']) if result['sort']
    result
  end

  def sort(values)
    Array.wrap(values).map do |entry|
      case entry
      when String then sort_field(entry)
      when Hash
        entry.to_h do |field, options|
          if options.is_a?(Hash) && (options.keys - %w[order mode missing unmapped_type numeric_type format]).any?
            raise SearchIndex::UnsupportedQuery, 'Unsupported sort option'
          end

          [sort_field(field), options]
        end
      else raise SearchIndex::UnsupportedQuery, 'Invalid sort'
      end
    end
  end

  def sort_field(field)
    raise SearchIndex::UnsupportedQuery, 'Unsupported sort field' if field.start_with?('_') && %w[_uid _doc _score].exclude?(field)

    field == '_uid' ? '__fm.uid' : SearchIndex::Schema.keyword_field(field)
  end
end
