class UsersController < ApplicationController
  def new
    @user = User.new        
  end

  def status
  end
  
  def show
    remote_ip = request.remote_ip
    hdr = env['HTTP_USER_AGENT']
    sid = session.id
    render json: 'ip address: '+remote_ip+' UserAgent: '+hdr+' session id: '+sid
  end
  
  def create
  end

  def eval_age
  # calculate age for COPA eligibility
#      @age = Time.zone.now.year-@user.birth_year    
    @age = Time.zone.now.year-params[:user][:birth_year].to_i
# BUG: calculate age correctly  
    if @age<13 then
      redirect_to '/users/show'
    else  
      ip_address = request.remote_ip

      if User.where(ip_address: ip_address).exists? then
        first_time_user=false
        p 'EVALAGE: USER EXISTS'
      else
        first_time_user=true
        p 'EVALAGE: USER DOES NOT EXIST'
      end

      if (first_time_user) then
        # Create a new-user record
        p 'EVALAGE: FIRST TIME USER'
        @user = User.new(user_params)
        @user.user_agent = env['HTTP_USER_AGENT']
        @user.session_id = session.id
        @user.user_id = SecureRandom.hex(16)
        @user.ip_address = ip_address
        @user.tos = false
        @user.number_of_attempts_in_last_24hrs=1
        @user.watch_listed=false
        @user.black_listed=false
        @user.attempts_time_stamps_array = [Time.now]
        @user.save
        redirect_to '/users/tos'
      else
      end
    
      if (first_time_user==false) then
        user=User.where(ip_address: ip_address).first
        #NTS: Why do I have to stop at first. Optimizes. But there should be not more than 1 entry.
        p user
        if user.black_listed==true then
          redirect_to '/users/show'
        else
          p 'EVALAGE: REPEAT USER'
          user.birth_month=params[:user][:birth_month]
          user.birth_year=params[:user][:birth_year]    
          user.session_id = session.id
          user.tos = false
          user.attempts_time_stamps_array = user.attempts_time_stamps_array + [Time.now]
          user.number_of_attempts_in_last_24hrs=user.attempts_time_stamps_array.count { |x| x > (Time.now-1.day) }
          user.save
          p user
          redirect_to '/users/tos'
        end
      end
    end
  end
  
  def sign_tos
    
    user=User.find_by session_id: session.id
    p user
    user.tos=true
    

    if ( user.number_of_attempts_in_last_24hrs==nil ) then
      user.number_of_attempts_in_last_24hrs=user.attempts_time_stamps_array.count { |x| x > (Time.now-1.day) }
    else
    end
    
    user.save
    
    if ( user.attempts_time_stamps_array.length==1 ) then
      p 'FIRST TIME USER'
      redirect_to '/users/qq2'
    else
      p 'A REPEAT USER'
      if (user.number_of_attempts_in_last_24hrs < 400) then
        # review 5
        # No need to ask qualification questions, just show offers
#      redirect_to '/users/show'
        redirect_to '/users/qq2' # temporary - delete
      else
        p 'Exceeded quota of surveys to fill for today'
  #     redirect_to '/users/show'
        redirect_to '/users/qq2' # temporary - delete
      end
    end
  end
  
  def gender
    user=User.find_by session_id: session.id
    user.gender=params[:gender]
    user.save
    redirect_to '/users/tq1'
  end
  
  def trap_question_1
    user=User.find_by session_id: session.id
    user.trap_question_1_response=params[:color]
    if params[:color]=="Green" then
      user.save
      redirect_to '/users/qq3'
    else
      redirect_to '/users/show'
    end
  end
  
  def trap_question_2a_US
    user=User.find_by session_id: session.id
    user.trap_question_2a_response=params[:trap_question_2a_response]
    user.save
    redirect_to '/users/qq6_US'
  end

  def trap_question_2a_CA
    user=User.find_by session_id: session.id
    user.trap_question_2a_response=params[:trap_question_2a_response]
    user.save
    redirect_to '/users/qq6_CA'
  end
  
  def trap_question_2a_IN
    user=User.find_by session_id: session.id
    user.trap_question_2a_response=params[:trap_question_2a_response]
    user.save
    redirect_to '/users/qq6_IN'
  end
  
  def trap_question_2b
    user=User.find_by session_id: session.id
    user.trap_question_2b_response=params[:trap_question_2b_response]
    if params[:trap_question_2b_response] != user.trap_question_2a_response then
      if user.trap_question_1_response != "Green" then
        if user.watch_listed then
          user.black_listed=true
          user.save
          redirect_to '/users/show'
        else
          user.watch_listed=true
          user.save
          redirect_to '/users/show'
        end
      else
        user.save
        redirect_to '/users/show'
      end
    else
      user.save
      redirect_to '/users/qq9'
    end
  end    
  
  def country
    user=User.find_by session_id: session.id
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
    user=User.find_by session_id: session.id
    user.ZIP=params[:zip]
    user.save
    redirect_to '/users/qq5_US'
  end
  
  def zip_CA
    user=User.find_by session_id: session.id
    user.ZIP=params[:zip]
    user.save
    redirect_to '/users/qq5_CA'
  end
  
  def zip_IN
    user=User.find_by session_id: session.id
    user.ZIP=params[:zip]
    user.save
    redirect_to '/users/qq5_IN'
  end
  
  def ethnicity_US
    user=User.find_by session_id: session.id
    user.ethnicity=params[:ethnicity]
    user.save
    redirect_to '/users/tq2a_US'
  end
  
  def ethnicity_CA
    user=User.find_by session_id: session.id
    user.ethnicity=params[:ethnicity]
    user.save
    redirect_to '/users/tq2a_CA'
  end
  
  def ethnicity_IN
    user=User.find_by session_id: session.id
    user.ethnicity=params[:ethnicity]
    user.save
    redirect_to '/users/tq2a_IN'
  end
  
  def householdincome
    user=User.find_by session_id: session.id
    user.householdincome=params[:hhi]
    user.save
    redirect_to '/users/show'
  end
  
  def race_US
    user=User.find_by session_id: session.id
    user.race=params[:race].to_s
    user.save
    redirect_to '/users/qq7_US'
  end
  
  def race_CA
    user=User.find_by session_id: session.id
    user.race=params[:race].to_s
    user.save
    redirect_to '/users/qq7_CA'
  end
  
  def race_IN
    user=User.find_by session_id: session.id
    user.race=params[:race].to_s
    user.save
    redirect_to '/users/qq7_IN'
  end
  
  def education_US
    user=User.find_by session_id: session.id
    user.eduation=params[:education]
    user.save
    redirect_to '/users/qq8_US'
  end
  
  def education_CA
    user=User.find_by session_id: session.id
    user.eduation=params[:education]
    user.save
    redirect_to '/users/qq8_CA'
  end
  
  def education_IN
    user=User.find_by session_id: session.id
    user.eduation=params[:education]
    user.save
    redirect_to '/users/qq8_IN'
  end

  def householdincome_US
    user=User.find_by session_id: session.id
    user.householdincome=params[:hhi]
    user.save
    redirect_to '/users/tq2b'
  end

  def householdincome_CA
    user=User.find_by session_id: session.id
    user.householdincome=params[:hhi]
    user.save
    redirect_to '/users/tq2b'
  end

  def householdincome_IN
    user=User.find_by session_id: session.id
    user.householdincome=params[:hhi]
    user.save
    redirect_to '/users/tq2b'
  end
  
  def householdcomp
    user=User.find_by session_id: session.id
    user.householdcomp=params[:householdcomp][:range]
    user.save
    redirect_to '/users/show'
  end
    
  private
    def user_params
      params.require(:user).permit(:birth_month, :birth_year)
    end

end