module Stats
  class Account
    include Elasticsearch::Persistence::Model
    include StatConcern
  end
end
