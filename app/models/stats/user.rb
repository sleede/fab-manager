module Stats
  class User
    include Elasticsearch::Persistence::Model
    include StatConcern
  end
end
