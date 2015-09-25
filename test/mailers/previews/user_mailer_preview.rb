# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/account_activation
  def account_activation
    user = User.first
    user.activation_token = User.new_token
    UserMailer.account_activation(user)
  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/password_reset
  def password_reset
    user = User.first
    user.reset_token = User.new_token
    UserMailer.password_reset(user)
  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/authorization_receipt
  #NOTE: when i created this i had to modify the seeds file to change all the AUTHORIZED toteitems to be ADDED.
  #then i had to use the browser to execute an authorization to get all the db info associated properly for this to work
  def authorization_receipt
    user = User.find_by(email: "c1@c.com")
    authorization = user.tote_items.first.checkouts.last.authorizations.last    
    UserMailer.authorization_receipt(user, authorization)
  end

end
