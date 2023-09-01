# frozen_string_literal: true

# This is a statistical data saved in ElasticSearch, about a project publication
class Stats::Project
  include Elasticsearch::Persistence::Model
  include StatConcern

  attribute :projectId, Integer
  attribute :name, String
  attribute :licence, Hash
  attribute :themes, Array
  attribute :components, Array
  attribute :machines, Array
  attribute :users, Integer
  attribute :status, String
  attribute :projectUserNames, Array
end
