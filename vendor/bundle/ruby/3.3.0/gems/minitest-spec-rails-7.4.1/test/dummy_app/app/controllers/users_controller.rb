class UsersController < ApplicationController
  def index
    @users = User.all
    render layout: false
  end

  def update
    redirect_to users_url
  end
end
