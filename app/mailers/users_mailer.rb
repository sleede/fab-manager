class UsersMailer < BaseMailer
  def notify_user_account_created(user, generated_password)
    @user = user
    @generated_password = generated_password
    mail(to: @user.email, subject: t('users_mailer.notify_user_account_created.subject'))
  end
end
