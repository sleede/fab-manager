# frozen_string_literal: true

json.extract! @user, :id, :email, :first_name, :last_name
json.name @user.profile.full_name
