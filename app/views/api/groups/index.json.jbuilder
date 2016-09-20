json.cache! ['v1', @groups] do
  json.partial! 'api/groups/group', collection: @groups, as: :group
end
