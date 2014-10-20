class UsersController < ApplicationController
  def new
    @user = User.new  
  end

  def status
  end
  
  def show
    @state_id = params[:id]
  end
  
  def create
  end

  def eval_age
    @user = User.new(user_params)
    @age = Time.zone.now.year-@user.birth_year
    if @age>13 then @user.save
      # Handle a successful save.
      redirect_to '/users/qq1'
    else
      redirect_to '/users/show'
    end
  end
  
  def qq1 
  end
  
  def sign_tos
    user=User.last
    user.tos=true
    user.save
    redirect_to '/users/qq2'
  end
  
  def gender
    user=User.last
    user.gender=params[:gender]
    user.save
    redirect_to '/users/qq3'
  end
  
  private
    
    def user_params
      params.require(:user).permit(:birth_month, :birth_year)
    end
end
