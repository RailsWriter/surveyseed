class UsersController < ApplicationController
  def new
    @user = User.new  
  end

  def status
  end
  
  def show
    data = {
          'request.remote_ip' => request.remote_ip,
          'request.ip' => request.ip,
        }
        
    hdr = env['HTTP_USER_AGENT']
    sid = session.id

        render json: 'ip address: '+request.remote_ip+' Hrd: '+hdr+' session id: '+sid 
  end
  
  def create
  end

  def eval_age
    @user = User.new(user_params)
    @age = Time.zone.now.year-@user.birth_year
    
    @user.ip_address = request.remote_ip
    @user.user_agent = env['HTTP_USER_AGENT']
    @user.session_id = session.id
    
    if @age>13 then @user.save
      redirect_to '/users/tos'
    else
      redirect_to '/users/show'
    end
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
  
  def country
    user=User.last
    user.country=params[:country]
    user.save
    if user.country=="USA" then 
      redirect_to '/users/qq4_US'
    else
      if user.country=="Canada" then
        redirect_to '/users/qq4_CA'
      else
        redirect_to '/users/qq4_IN'
      end
    end
  end
  
  def zip_US
    user=User.last
    user.ZIP=params[:zip]
    user.save
    redirect_to '/users/qq5_US'
  end
  
  def zip_CA
    user=User.last
    user.ZIP=params[:zip]
    user.save
    redirect_to '/users/qq5_CA'
  end
  
  def zip_IN
    user=User.last
    user.ZIP=params[:zip]
    user.save
    redirect_to '/users/qq5_IN'
  end
  
  def ethnicity_US
    user=User.last
    user.ethnicity=params[:ethnicity]
    user.save
    redirect_to '/users/qq6_US'
  end
  
  def ethnicity_CA
    user=User.last
    user.ethnicity=params[:ethnicity]
    user.save
    redirect_to '/users/qq6_CA'
  end
  
  def ethnicity_IN
    user=User.last
    user.ethnicity=params[:ethnicity]
    user.save
    redirect_to '/users/qq6_IN'
  end
  
  def householdincome
    user=User.last
    user.householdincome=params[:hhi]
    user.save
    redirect_to '/users/show'
  end
  
  def race_US
    user=User.last
    user.race=params[:race].to_s
    user.save
    redirect_to '/users/qq7_US'
  end
  
  def race_CA
    user=User.last
    user.race=params[:race].to_s
    user.save
    redirect_to '/users/qq7_CA'
  end
  
  def race_IN
    user=User.last
    user.race=params[:race].to_s
    user.save
    redirect_to '/users/qq7_IN'
  end
  
  def education_US
    user=User.last
    user.eduation=params[:education]
    user.save
    redirect_to '/users/qq8_US'
  end
  
  def education_CA
    user=User.last
    user.eduation=params[:education]
    user.save
    redirect_to '/users/qq8_CA'
  end
  
  def education_IN
    user=User.last
    user.eduation=params[:education]
    user.save
    redirect_to '/users/qq8_IN'
  end

  def householdincome_US
    user=User.last
    user.householdincome=params[:hhi]
    user.save
    redirect_to '/users/qq9'
  end

  def householdincome_CA
    user=User.last
    user.householdincome=params[:hhi]
    user.save
    redirect_to '/users/qq9'
  end

  def householdincome_IN
    user=User.last
    user.householdincome=params[:hhi]
    user.save
    redirect_to '/users/qq9'
  end
  
  def householdcomp
    user=User.last
    user.householdcomp=params[:householdcomp][:range]
    user.save
    redirect_to '/users/show'
  end
    
  private
    
    def user_params
      params.require(:user).permit(:birth_month, :birth_year)
    end
  
  end
