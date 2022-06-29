# frozen_string_literal: true

json.array!(@credits) do |credit|
  json.partial! 'api/credits/credit', credit: credit
end
