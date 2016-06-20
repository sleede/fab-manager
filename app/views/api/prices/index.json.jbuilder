json.cache! @prices do
  json.prices @prices, partial: 'api/prices/price', as: :price
end
