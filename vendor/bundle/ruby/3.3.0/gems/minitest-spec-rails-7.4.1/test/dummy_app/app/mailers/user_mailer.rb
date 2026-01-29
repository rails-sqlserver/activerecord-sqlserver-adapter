class UserMailer < ActionMailer::Base
  default from: 'rails@minitest.spec'

  def welcome(user)
    @user = user
    mail to: @user.email, subject: 'Welcome', body: "Welcome to Minitest::Spec #{@user.email}!"
  end
end
