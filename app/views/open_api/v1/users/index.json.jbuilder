json.users @users do |user|
  json.partial! 'open_api/v1/users/user', user: user
end
