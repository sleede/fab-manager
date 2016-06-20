json.cache! @groups do
  json.partial! 'api/groups/group', collection: @groups, as: :group
end
