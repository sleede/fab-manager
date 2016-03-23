module Stats
  class Project
    include Elasticsearch::Persistence::Model
    include StatConcern

    attribute :projectId, Integer
    attribute :name, String
    attribute :licence, Hash
    attribute :themes, Array
    attribute :components, Array
    attribute :machines, Array
    attribute :users, Integer
  end
end
