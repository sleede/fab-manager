# frozen_string_literal: true

client = if Rails.env.test?
           Elasticsearch::Client.new host: "http://#{Rails.application.secrets.elaticsearch_host}:9200", log: false
         else
           Elasticsearch::Client.new host: "http://#{Rails.application.secrets.elaticsearch_host}:9200", log: true
         end

Elasticsearch::Model.client = client
Elasticsearch::Persistence.client = client
