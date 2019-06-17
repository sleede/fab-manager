json.users @users do |user|
  json.extract! user, :id, :email, :first_name, :last_name
  json.name user.profile.full_name
end
