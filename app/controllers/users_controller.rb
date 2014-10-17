class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def status
  end
  
  def create
    @user = User.new(user_params)
    if @user.save
      # Handle a successful save.
      redirect_to '/leads/thanks'
    else
      render 'home'
    end
  end
  
  private
    
    def user_params
      params.require(:user).permit(:birth_month, :birth_year)
    end
end
