json.users @users do |user|
  json.extract! user, :id, :email, :first_name, :last_name
  json.name "#{user.first_name} #{user.last_name}"
end
