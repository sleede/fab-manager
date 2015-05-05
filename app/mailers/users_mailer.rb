class UsersMailer < BaseMailer
  def notify_member_account_is_created(user, generated_password)
    @user = user
    @generated_password = generated_password
    mail(to: @user.email, subject: "Votre compte Fab Lab a bien été créé.")
  end
end
