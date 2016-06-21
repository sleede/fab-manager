json.cache! @prices do
  json.partial! 'api/prices/price', collection: @prices, as: :price
end
