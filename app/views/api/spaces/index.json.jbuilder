# frozen_string_literal: true

json.array!(@spaces) do |space|
  json.partial! 'api/spaces/space', space: space

  parent = @spaces_indexed_with_parent[space]
  if parent
    json.parent do
      json.name parent.name
    end
  end

  json.children @spaces_grouped_by_parent_id[space.id] do |child|
    json.name child.name
  end
end
