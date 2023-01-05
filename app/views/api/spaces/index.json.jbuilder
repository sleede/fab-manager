# frozen_string_literal: true

json.array!(@spaces) do |space|
  json.partial! 'api/spaces/space', space: space
end
