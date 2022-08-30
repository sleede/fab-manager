# frozen_string_literal: true

json.spaces @spaces do |space|
  json.partial! 'open_api/v1/spaces/space', space: space
  json.extract! space, :description, :characteristics
end
