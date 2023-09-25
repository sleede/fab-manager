# frozen_string_literal: true

json.array! @children do |child|
  json.partial! 'child', child: child
end
