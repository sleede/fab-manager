client = Elasticsearch::Client.new host: "http://#{Rails.application.secrets.elaticsearch_host}:9200", log: true
Elasticsearch::Model.client = client
Elasticsearch::Persistence.client = client
