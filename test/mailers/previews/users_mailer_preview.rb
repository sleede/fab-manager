# frozen_string_literal: true

class UsersMailerPreview < ActionMailer::Preview
  def notify_user_account_created
    UsersMailer.notify_user_account_created(User.first, 'test')
  end
end
