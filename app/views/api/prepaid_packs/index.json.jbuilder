# frozen_string_literal: true

json.array! @packs do |pack|
  json.partial! 'api/prepaid_packs/pack', pack: pack
end
