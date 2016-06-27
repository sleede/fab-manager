json.array! @clients do |client|
  json.partial! 'api/open_api_clients/client', client: client
end
