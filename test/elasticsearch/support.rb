# frozen_string_literal: true

# Explicit opt-in only; never loaded by the standard *_test.rb discovery.
module ElasticsearchContractSupport
  def reset_search_indices
    raise 'Set ES_CONTRACT_ISOLATED=1 for disposable ES9 services' unless ENV['ES_CONTRACT_ISOLATED'] == '1'

    @client = SearchIndex::Connection.client
    assert_match(/^9\./, @client.info.dig('version', 'number'))
    SearchIndex::FAMILIES.each do |family|
      index = SearchIndex::Schema.physical(family)
      @client.indices.delete(index: index) if @client.indices.exists?(index: index)
    end
    SearchIndex.initialize_schema!
  end
end
