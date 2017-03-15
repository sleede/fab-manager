if Rails.env.test?
  client = Elasticsearch::Client.new host: "http://#{Rails.application.secrets.elaticsearch_host}:9200", log: false
else
  client = Elasticsearch::Client.new host: "http://#{Rails.application.secrets.elaticsearch_host}:9200", log: true
end

Elasticsearch::Model.client = client
Elasticsearch::Persistence.client = client
