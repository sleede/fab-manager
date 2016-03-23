client = Elasticsearch::Client.new host: "http://#{ENV["ELASTICSEARCH_HOST"]}:9200", log: true
Elasticsearch::Model.client = client
Elasticsearch::Persistence.client = client
