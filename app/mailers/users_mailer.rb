class UsersMailer < BaseMailer
  def notify_member_account_is_created(user, generated_password)
    @user = user
    @generated_password = generated_password
    mail(to: @user.email, subject: "Your Fab Lab account has been created.")
  end
end
