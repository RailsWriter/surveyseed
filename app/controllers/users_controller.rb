class UsersController < ApplicationController

  require 'mixpanel-ruby'
  require 'hmac-md5'
    
  def eval_age  

    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    if (params[:age].empty? == false) then
      @age = params[:age]
    else
      redirect_to '/users/new'
      return
    end

     # Check for COPA eligibility

    if @age.to_i<13 then
      ip_address = request.remote_ip
      tracker.track(ip_address, 'NS<13')
      redirect_to '/users/nosuccess'
    else  
      # Enter the user with the following credentials in our system or find user's record  
      ip_address = request.remote_ip
      session_id = session.id
      netid = params[:netid]
      clickid = params[:clickid]
      userRecordId = params[:userRecordId]      
      
      # Keep track of clicks on each network as Flag2
      
      if netid != nil then
        @SSnet = Network.find_by netid: netid
        if @SSnet == nil then
          print "************************************ Bad NetworkId ********************"
          puts
          redirect_to '/users/nosuccess'
        else
          if @SSnet.Flag2 == nil then
            @SSnet.Flag2 = "1" 
            @SSnet.save
          else
            @SSnet.Flag2 = (@SSnet.Flag2.to_i + 1).to_s
            @SSnet.save
          end
        end      
      else
        print "************************************ No NetworkId ********************"
        puts
        redirect_to '/users/nosuccess'
        return      
      end

      if (netid == "MMq0514UMM20bgf17Yatemoh") then
        print "*******DEBUG************** New start by a Panel User from MMq0514UMM20bgf17Yatemoh netid with userRecordId = ", userRecordId, "*************"
        puts
      else
      end

      tracker.track(ip_address, 'Age')
      
      # Change this to include validating a cookie first(more unique compared to IP address id) before verifying by IP address      
      # if ((User.where(ip_address: ip_address).exists?) && (User.where(session_id: session.id).exists?)) then
 
      if (netid == "MMq0514UMM20bgf17Yatemoh") || (User.where("ip_address = ? AND session_id = ?", ip_address, session_id).first!=nil)
        first_time_user=false
        # p '********* EVAL_AGE: USER EXISTS'
      else
        first_time_user=true
        # p 'EVAL_AGE: USER DOES NOT EXIST'
      end

      if (first_time_user) then
        # Create a new-user record
        #        p '****************** EVAL_AGE: Creating new record for FIRST TIME USER'
        #  @user = User.new(user_params)
        @user = User.new
        @user.age = @age
        @user.netid = netid
        @user.clickid = clickid

        # if deriving country from IP address => disable country question
        #@user.country = @countryPrecode
        
        # Initialize user ride related lists. These protect from getting old lists, if the user restarts taking surveys in the same session after a long break. However, these get a blank entry on the list due to save action
        
        @user.QualifiedSurveys = Array.new
        @user.SurveysWithMatchingQuota = Array.new
        @user.SupplierLink = Array.new
        
        @user.user_agent = env['HTTP_USER_AGENT']
        @user.session_id = session_id
        @user.user_id = SecureRandom.urlsafe_base64
        @user.ip_address = ip_address
        @user.tos = false
        @user.watch_listed=false
        @user.black_listed=false
        @user.number_of_attempts_in_last_24hrs=1
        @user.attempts_time_stamps_array = [Time.now]
        @user.save
        redirect_to '/users/tos'
      else
      end    
    
      # This DB call should be optimized by using the id of record already found before
      
      if (first_time_user==false) then
        if (netid == "MMq0514UMM20bgf17Yatemoh") then
          user = User.find(userRecordId)
        else
          user = User.where("ip_address = ? AND session_id = ?", ip_address, session_id).first
        end

        print "*** DEBUG ******* REPEAT USER. Existing User Record is: ", user
        puts

        if user.black_listed==true then
          p '******************* EVAL_AGE: REPEAT USER is Black listed'
          # Send to userride to be termed. ***** This can be changed to redirect to nosuccess? *****
          userride (session_id)
        else
          p '******************* EVAL_AGE: Modifying existing user record of a REPEAT USER with current info'

          user.age = @age
          user.netid = netid
          user.clickid = clickid
          user.session_id = session_id

          # if deriving country from IP address  => disable country question
          #user.country = @countryPrecode 
               
          # These get a blank entry on the list due to save action?
          user.QualifiedSurveys = []
          user.SurveysWithMatchingQuota = []
          user.SupplierLink = []
          # user.session_id = session.id - redundant, as it already exists
          user.tos = false
          user.attempts_time_stamps_array = user.attempts_time_stamps_array + [Time.now]
          user.number_of_attempts_in_last_24hrs=user.attempts_time_stamps_array.count { |x| x > (Time.now-1.day) }
          user.save
          redirect_to '/users/tos'
        end
      else
      end
    end
  end

  def capturefp

    if params[:fingerprint].empty? == false      
      @fp = params[:fingerprint].to_i
    #  print "----------------->>>>>>>>>>>> fp: ", @fp
    #  puts
      
      user=User.find_by session_id: session.id
      user.fingerprint = @fp
      user.save    
      
      redirect_to '/users/tos'
    else
      redirect_to '/users/tos'
    end        
  end
  
  def sign_tos

    #   tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
      
    user=User.find_by session_id: session.id
    user.tos=true

    #   tracker.track(user.ip_address, 'TOS')

    # Update number of attempts in last 24 hrs record of the user
    if ( user.number_of_attempts_in_last_24hrs==nil ) then
      user.number_of_attempts_in_last_24hrs=user.attempts_time_stamps_array.count { |x| x > (Time.now-1.day) }
    else
    end
    
    user.save
    
    # Address good and bad repeat access behaviour after they have resigned TOS (PP)
    if ( user.attempts_time_stamps_array.length==1 ) then
      p '*******DEBUG************ TOS: FIRST TIME USER or First time returning Panelist'
      redirect_to '/users/qq2'
    else
      p '**********DEBUG********** TOS: A REPEAT USER'
      # set 24 hr survey attempts in separate sessions from same device/IP address here
      if (user.number_of_attempts_in_last_24hrs < 20) then
        if (user.industries.length == 0) then 
          #industries is an Array so verify length and not nil
          # this user did not provide full profile info the first time
          print '** DEBUG REPEAT USER ***** industries field is empty ***********'
          puts
          redirect_to '/users/qq2'
        else
          # skip gender and other demo questions due to responses in last 24 hrs
          print '** DEBUG REPEAT USER ***** industries field is NOT empty ***********'
          puts
          redirect_to '/users/qq12Returning'
        end      
      else
        # user has made too many attempts to take surveys
        p '******* More than 20 attempts to take a survey in last 24 hrs ***********'
        redirect_to '/users/24hrsquotaexceeded'
      end
    end
      
    # set 24 hr survey completes quota here
    #    if (user.SurveysCompleted[count { |x| x > (Time.now-1.day) } == 5) then
    #       p 'Exceeded quota of surveys to fill for today'
    #       redirect_to '/users/24hrsquotaexceeded'
    #       return
    #     else
    #     end
  end  
  
  def gender
    
    #  tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
  
    user=User.find_by session_id: session.id
    
    #    tracker.track(user.ip_address, 'Gender')

    if params[:gender] != nil
      user.gender=params[:gender]
      user.save
      redirect_to '/users/tq1'
    else
      redirect_to '/users/qq2'
    end    
  end
  
  def trap_question_1
    
    #  tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
  
    
    user=User.find_by session_id: session.id
    
    #  tracker.track(user.ip_address, 'Trap Q1')
    
    user.trap_question_1_response=params[:color]
    if params[:color]=="Green" then
      user.save           
      redirect_to '/users/qq3'
    else
      user.watch_listed=true
      user.save
      # Flash user to pay attention
      flash[:alert] = "Please pay attention to your responses!"
      redirect_to '/users/tq1'
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
    redirect_to '/users/qq7_IN'
  end
  
  def trap_question_2b
    user=User.find_by session_id: session.id
    user.trap_question_2b_response=params[:trap_question_2b_response]
    if params[:trap_question_2b_response] != user.trap_question_2a_response then
      if user.trap_question_1_response != "Green" then
        if user.watch_listed then
          user.black_listed=true
          user.save
          # send to quality term the user
          userride (session_id)
        else
          user.watch_listed=true
          user.save
          # Flash user to pay attention
          flash[:alert] = "Please pay attention to your responses!"
          redirect_to '/users/tq2b'
        end
      else
        user.save
        # Flash user to pay attention
        flash[:alert] = "Please pay attention to your responses!"
        redirect_to '/users/tq2b'
      end
    else
      user.save
      redirect_to '/users/qq9'
    end
  end    
  
  def country    
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    
    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'Country')
    
    user.country=params[:country]
    user.save
    
    if user.country=="9" then 
      redirect_to '/users/qq4_US'
    else
      if user.country=="6" then
        redirect_to '/users/qq4_CA'
      else
        if user.country=="5" then
          redirect_to '/users/qq4_AU'
        else
          if user.country=="7" then
            redirect_to '/users/qq4_IN'
          else
            print "**** DEBUG Country **********", params[:country], " Session_id ", session_id
            puts
            # if user.country=="0" then
            #  redirect_to '/users/nosuccess'
            # else
             redirect_to '/users/qq3'
            # end
          end
        end
      end
    end  
  end
  
  def zip_US

    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'Zip')
    
    if params[:zip].empty? == false
      user.ZIP=params[:zip]
      user.save
      redirect_to '/users/qq7_US'
    else
      redirect_to '/users/qq4_US'
    end
  end
  
  def zip_CA

    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'CA_Zip')
    
    if params[:zip].empty? == false
      user.ZIP=params[:zip].upcase
      user.save
      redirect_to '/users/qq7_CA'
    else
      redirect_to '/users/qq4_CA'
    end    
  end
  
  def zip_IN

    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    
    
    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'IN_PIN')
 
    
    if params[:zip].empty? == false
      user.ZIP=params[:zip]
      user.save
      redirect_to '/users/qq7_IN'
    else
      redirect_to '/users/qq4_IN'
    end      
  end
  
  def zip_AU
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    
    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'AU_Zip')

    if params[:zip].empty? == false
      user.ZIP=params[:zip]
      user.save
      redirect_to '/users/qq7_AU'
    else
      redirect_to '/users/qq4_AU'
    end    
  end
  
  def ethnicity_US
    
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'ethnicity_US')
    
    if params[:ethnicity] != nil
      user.ethnicity=params[:ethnicity]
      user.save
      redirect_to '/users/qq6_US'
    else
      redirect_to '/users/qq5_US'
    end    
  end
  
  def ethnicity_CA

    user=User.find_by session_id: session.id
    
    if params[:ethnicity] != nil
      user.ethnicity=params[:ethnicity]
      user.save
      redirect_to '/users/qq6_CA'
    else
      redirect_to '/users/qq5_CA'
    end    
  end
  
  def ethnicity_IN

    user=User.find_by session_id: session.id
    
    if params[:ethnicity] != nil
      user.ethnicity=params[:ethnicity]
      user.save
      redirect_to '/users/qq6_IN'
    else
      redirect_to '/users/qq5_IN'
    end      
  end
  
  def race_US
    
    #    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    #    tracker.track(user.ip_address, 'race_US')
    
    if params[:race] != nil
      user.race=params[:race]
      user.save
      redirect_to '/users/qq10'
    else
      redirect_to '/users/qq6_US'
    end      
  end
  
  def race_CA
    
    # NOTE: make QQ6 with radio buttons and race not an array, delete to_s

    user=User.find_by session_id: session.id
    user.race=params[:race].to_s
    user.save
    redirect_to '/users/qq7_CA'
  end
  
  def race_IN
    # NOTE: make QQ6 with radio buttons and race not an array, delete to_s
    user=User.find_by session_id: session.id
    user.race=params[:race]
    user.save
    redirect_to '/users/qq7_IN'
  end
  
  def education_US
    
    # Note: typo in user.eduation
    
    #    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    #    tracker.track(user.ip_address, 'education_US')
    
    if params[:education] != nil
      user.eduation=params[:education]
      user.save
      redirect_to '/users/qq8_US'
    else
      redirect_to '/users/qq7_US'
    end    
  end
  
  def education_CA
    # Note: typo in user.eduation
    
    #    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    #     tracker.track(user.ip_address, 'education_CA')
    
    if params[:education] != nil
      user.eduation=params[:education]
      user.save
      redirect_to '/users/qq8_CA'
    else
      redirect_to '/users/qq7_CA'
    end    
  end
  
  def education_IN
    # Note: typo in user.eduation
    
    #    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    #    tracker.track(user.ip_address, 'education_IN')
    
    if params[:education] != nil
      user.eduation=params[:education]
      user.save
      redirect_to '/users/qq8_IN'
    else
      redirect_to '/users/qq7_IN'
    end    
  end
  
  def education_AU
    # Note: typo in user.eduation
    
    #    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    #    tracker.track(user.ip_address, 'education_AU')
    
    if params[:education] != nil
      user.eduation=params[:education]
      user.save
      redirect_to '/users/qq8_AU'
    else
      redirect_to '/users/qq7_AU'
    end   
  end

  def householdincome_US  
    
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'hhi_US')
    
    if params[:hhi] != nil
      user.householdincome=params[:hhi]
      user.save
      redirect_to '/users/qq5_US'
    else
      redirect_to '/users/qq8_US'
    end    
  end

  def householdincome_CA
    
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'hhi_CA')
    
    if params[:hhi] != nil
      user.householdincome=params[:hhi]
      user.save
      redirect_to '/users/qq10'
    else
      redirect_to '/users/qq8_CA'
    end    
  end

  def householdincome_IN  
    
    #    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    #     tracker.track(user.ip_address, 'hhi_IN')
    
    if params[:hhi] != nil
      user.householdincome=params[:hhi]
      user.save
      redirect_to '/users/qq10'
    else
      redirect_to '/users/qq8_IN'
    end
  end
  
  def householdincome_AU  
    
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'hhi_AU')
    
    if params[:hhi] != nil
      user.householdincome=params[:hhi]
      user.save      
      redirect_to '/users/qq10'
    else
      redirect_to '/users/qq8_AU'
    end    
  end
  
  def employment
    
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'employment')    
    
    if params[:employment] != nil
    #    user.householdcomp=params[:employment]
      user.employment=params[:employment]
      user.save
      redirect_to '/users/qq11'
    #      ranksurveysforuser(session.id)
    else
      redirect_to '/users/qq10'
    end    
  end
  
  def personalindustry  
    
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'pindustry')
    
    if params[:pindustry] != nil
      user.pindustry=params[:pindustry]
      user.save
      redirect_to '/users/qq13'
    else
      redirect_to '/users/qq11'
    end    
  end
  
  def jobtitleaction  
    
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'jobtitle')
    
    if params[:jtitle] != nil
      user.jobtitle=params[:jtitle]
      user.save
      redirect_to '/users/qq14'
    else
      redirect_to '/users/qq13'
    end    
  end 
  
  def childrenaction  
    
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'children')
    
    if params[:children] != nil
      user.children=params[:children]
      user.save
      # print "****** user.children.flatten: ", user.children.flatten
      # puts
      # print "******* user.children[0]: ", user.children[0]
      # puts
      redirect_to '/users/qq15'
    else
      redirect_to '/users/qq14'
    end    
  end 
  
  def industriesaction  
    
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    # tracker.track(user.ip_address, 'industries')
    
    if params[:industries] != nil
      user.industries=params[:industries]
      user.save
      # print "------------------->>>>****** user.industries.flatten: ", user.industries.flatten
      # puts
      # print "------------------->>>>>>******* user.industries[0]: ", user.industries[0]
      # puts
      redirect_to '/users/qq12'
    else
      redirect_to '/users/qq15'
    end    
  end
  
  def pleasewait
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'pleasewait')    
    
    print "BUG Repeat User: ", user.user_id, " of country ", user.country, " of Gender ", user.gender, " Time 2 start FED search: ", Time.now
    puts
    
    ranksurveysforuser(session.id)    
  end

  def join_panel  

    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    if (User.where('session_id=?', session.id).exists?) then
      user=User.find_by session_id: session.id

      if user.netid == "MMq0514UMM20bgf17Yatemoh" then
        # do nothing, because the user is already in the system
        p "****DEBUG ********** The user is already a Panelist *****************"
          redirect_to '/users/alreadyPanelist'
      else
        if (params[:emailid].empty? == false) then
          user.emailId = params[:emailid]
          user.password = 'Ketsci'+user.user_id[0..3]
          user.userType='1'
          user.surveyFrequency = '2'
          # Sends email to user when panelist is created. Remove netid condition before going live.
          # if user.netid == 'KsAnLL23qacAHoi87ytr45bhj8' then
            p "========================================================Sending Welcome MAIL to new panelist ================================"
            PanelMailer.welcome_email(user).deliver_now
          # else
          #   #do nothing
          # end

          user.save

          tracker.track(user.ip_address, 'panelistregistered')
          redirect_to '/users/thanks'
        else
          p "************** We do not have users emailid in join_panel *****************"
          redirect_to '/users/thanks'
        end
      end
    else
      p "************** We do not have users session_id in join_panel *****************"
      redirect_to '/users/thanks'
    end

  end

  def login
    if ((params[:credentials]["emailId"] != nil) && (params[:credentials]["password"] != nil)) then
      print "****************** Received login credentials ", params[:credentials]
      puts
      user = User.where('emailId=? AND password=?', params[:credentials]["emailId"], params[:credentials]["password"]).first      
      if user!=nil then
        print "***************** Successful login: This person is a registered existing user: ", user
        puts
        render json: user
      else
        user = User.where('emailId=?', params[:credentials]["emailId"]).first
        if user != nil then
          print "************* Unsuccessful login: This UserID already exists, please provide correct default/chosen password *************"
          puts
          #format.json { render json: { message: "Unsuccessful login: This UserID already exists, please provide correct password" } }

          payload = {
            error: "Unsuccessful login: This UserID already exists, please provide correct password",
            status: 400
          }
          render :json => payload, :status => :bad_request
        else          
          ip_address = request.remote_ip
          session_id = session.id
          netid = params[:netid]
          clickid = params[:clickid]

          user=User.new
          
          user.QualifiedSurveys = Array.new
          user.SurveysWithMatchingQuota = Array.new
          user.SupplierLink = Array.new
          user.user_agent = env['HTTP_USER_AGENT']
          user.session_id = session_id
          user.user_id = SecureRandom.urlsafe_base64
          user.ip_address = ip_address
          user.tos = false
          user.watch_listed=false
          user.black_listed=false
          user.number_of_attempts_in_last_24hrs=0        
          user.emailId=params[:credentials]["emailId"]
          user.password=params[:credentials]["password"]
          user.userType='1'
          user.redeemRewards='1'
          user.surveyFrequency = '2'
          user.save
          print "***************** Successfully created a new panelist: ", user
          puts
          render json: user
        end
      end
    else
      respond_to do |format|
        #format.html # home.html.erb
        #format.json { render json: { message: "Unsuccessful login: No login credentials received" } }

        payload = {
          error: "Unsuccessful login: No login credentials received",
          status: 400
        }
        render :json => payload, :status => :bad_request


      end 
      p "***************** Unsuccessful login: Email or Password credentials were not received in POST for login **************"
    end
  end

  def surveyStats
    # GET https://www.ketsci.com/users/surveyStats?userRecordId=xyz
    # Response: completedSurveyStats = [["2017-01",5],["2017-02",3]]
    # @Url = request.original_url
    # @userRecordId = @Url.partition ("userRecordId=")
    #@user = User.find(@userRecordId[2])
    print "****************** Received userRecordId = ", params[:userRecordId]
    puts
    @user = User.find(params[:userRecordId])
    p "******** User Found in surveyStats ********"

    # SurveysAttempted and Completed by Month
    # WHAT ABOUT P2S or INV surveys - no way to count?

    if @user.SurveysCompleted.length > 0 then
      @CompletedSurveysTimestampsArray = @user.SurveysCompleted.keys
      (0..@CompletedSurveysTimestampsArray.length-1).each do |i|
        @CompletedSurveysTimestampsArray[i] = @CompletedSurveysTimestampsArray[i].to_s[0..6]
      end

      print "****************** @CompletedSurveysTimestampsArray is = ", @CompletedSurveysTimestampsArray
      puts

      @counts = Hash.new 0
      @CompletedSurveysTimestampsArray.each do |month|
        @counts[month] += 1
      end

      print "****************** @counts Hash is = ", @counts
      puts

      @countsArray = @counts.flatten

      print "****************** @countsArray is = ", @countsArray
      puts
      
      j=0
      k=0  
      completedSurveyStats = []    
      begin
        completedSurveyStats[k] = [@countsArray[j],@countsArray[j+1], '']
        k=k+1
        j=j+2
      end while j<@countsArray.length-1

      # remove the double array and format as expected
      completedSurveyStats = [['Genre', 'Completed',  {role: 'annotation'}], completedSurveyStats.flatten]

      print "****************** completedSurveyStats Array of Arrays is = ", completedSurveyStats
      puts

      render json: completedSurveyStats.to_json
    
    else
      # This user has not completed any surveys

      print "LOG: This user has not completed any surveys"
      puts
      
      completedSurveyStats = []
      render json: completedSurveyStats.to_json
    end  
  end

  def savePreferences
    if params[:preferences] != nil then
      print "****************** Received savePreferences parameters ", params[:preferences]
      puts
      # user = User.where('emailId=? AND password=?', params[:preferences]["emailId"], params[:preferences]["password"]).first    
      user = User.find(params[:preferences]["userId"])  
      if user!=nil then
        print "***************** Found registered existing user: ", user
        puts

        user.redeemRewards=params[:preferences]["redeemRewards"]
        user.surveyFrequency=params[:preferences]["surveyFrequency"]
        user.save
        print "***************** Saved new preferences: ", user
        puts
        render json: user
      else
        print "************* User not found. Provide correct userid/password *************"
        puts
        format.json { render json: { message: "User not found" } }
      end
    else
      respond_to do |format|
        #format.html # home.html.erb
        format.json { render json: { message: "No preferences received" } }
      end 
      p "***************** Nothing was received by savePreferences as preferences **************"
    end
  end
  
  # start to rankfedsurveys
  def ranksurveysforuser (session_id)

    require 'base64'
    require 'hmac-sha1'
    # @SHA1key = 'uhstarvsuio765jalksrWE'
    @SHA1key = 'dKyEuAdS/pwtc9VK8ihCVsMmSK8JyK6QlTuOLiOSQD1tiXyOTdrMurEi84lrhddMxYcbAvLLMgrKHiroeROYMw=='


    user=User.find_by session_id: session_id
    
    if user.gender == '1' then
      @GenderPreCode = [ "1" ]
    else
      @GenderPreCode = [ "2" ]
    end    
    
    if user.country == '6' then
    #      print "--------------------------->>>>>> First character of CA postalcode = ", user.ZIP.slice(0)
    #      puts
      
      case user.ZIP.slice(0)
      when "T"
        @provincePrecode = "1"
    #        puts "Assigned Alberta @provincePrecode = 1"
        
      when "V"
        @provincePrecode = "2"
    #        puts "Assigned BC @provincePrecode = 2"
        
      when "R"
        @provincePrecode = "3"
    #        puts "Assigned MB @provincePrecode = 3"
        
      when "E"
        @provincePrecode = "4"
    #        puts "Assigned NB @provincePrecode = 4"
        
      when "A"
        @provincePrecode = "5"
    #        puts "Assigned NL @provincePrecode = 5"
        
      when "X"
        @provincePrecode = "6"
    #        puts "Assigned NT @provincePrecode = 6"
        
      when "B"
        @provincePrecode = "7"
    #        puts "Assigned NS @provincePrecode = 7"
        
        # when "X"  # X would become a duplicate. Nunavut is teh least populated province so this is it
        # @provincePrecode = "8"
        # puts "Assigned NU @provincePrecode = 8"
        
      when "K"
        @provincePrecode = "9"
    #        puts "Assigned ON @provincePrecode = 9"
        
      when "L"
        @provincePrecode = "9"
    #        puts "Assigned ON @provincePrecode = 9"
        
      when "M"
        @provincePrecode = "9"
    #        puts "Assigned ON @provincePrecode = 9"
        
      when "N"
        @provincePrecode = "9"
    #        puts "Assigned ON @provincePrecode = 9"
        
      when "P"
        @provincePrecode = "9"
    #        puts "Assigned ON @provincePrecode = 9"

      when "C"
        @provincePrecode = "10"
    #        puts "Assigned PE @provincePrecode = 10"
        
      when "G"
        @provincePrecode = "11"
    #        puts "Assigned QC @provincePrecode = 11"
        
      when "H"
        @provincePrecode = "11"
    #        puts "Assigned QC @provincePrecode = 11"
        
      when "J"
        @provincePrecode = "11"
    #        puts "Assigned QC @provincePrecode = 11"
        
      when "S"
        @provincePrecode = "12"
    #        puts "Assigned SK @provincePrecode = 12"
        
      when "Y"
        @provincePrecode = "13"
    #        puts "Assigned YT @provincePrecode = 13"
      end
    else
    end # country == 6
    
    if @provincePrecode == nil then
      # wild guess
      @provincePrecode = "11"
    else
    end
           
    if user.country == '9' then
      @geo = UsGeo.find_by zip: user.ZIP
      
      if @geo == nil then
        @statePrecode = "0"
        @DMARegionCode = "0"
        @regionPrecode = "0"
        @dividionPrecode = "0"
        puts "NotApplicable PreCodes Used for INVALID ZIPCODE"
        
      else
      
        @DMARegionCode = @geo.DMARegionCode
        @regionPrecode = @geo.regionPrecode
        @divisionPrecode = @geo.divisionPrecode
        
        case @geo.State
        when "NotApplicable"
          @statePrecode = "0"
          print "NotApplicable PreCode Used for: ", @geo.State
          puts
        when "Alabama"
          @statePrecode = "1"
          print "Alabama PreCode Used for: ", @geo.State
          puts
        when "Alaska"
          @statePrecode = "2"
          print "Alaska PreCode Used for: ", @geo.State
          puts
        when "Arizona"
          @statePrecode = "3"
          print "Arizona PreCode Used for: ", @geo.State
          puts
        when "Arkansas"
          @statePrecode = "4"
          print "Arkansas PreCode Used for: ", @geo.State
          puts
        when "California"
          @statePrecode = "5"
          print "California PreCode Used for: ", @geo.State
          puts
        when "Colorado"
          @statePrecode = "6"
          print "Colorado PreCode Used for: ", @geo.State
          puts
        when "Connecticut"
          @statePrecode = "7"
          print "Connecticut PreCode Used for: ", @geo.State
          puts
        when "Delaware"
          @statePrecode = "8"
          print "Delaware PreCode Used for: ", @geo.State
          puts
        when "DistrictofColumbia"
          @statePrecode = "9"
          print "DistrictofColumbia PreCode Used for: ", @geo.State
          puts
        when "Florida"
          @statePrecode = "10"
          print "Florida PreCode Used for: ", @geo.State
          puts
        when "Georgia"
          @statePrecode = "11"
          print "Georgia PreCode Used for: ", @geo.State
          puts
        when "Hawaii"
          @statePrecode = "12"
          print "Hawaii PreCode Used for: ", @geo.State
          puts
        when "Idaho"
          @statePrecode = "13"
          print "Idaho PreCode Used for: ", @geo.State
          puts
        when "Illinois"
          @statePrecode = "14"
          print "Illinois PreCode Used for: ", @geo.State
          puts
        when "Indiana"
          @statePrecode = "15"
          print "Indiana PreCode Used for: ", @geo.State
          puts
        when "Iowa"
          @statePrecode = "16"
          print "Iowa PreCode Used for: ", @geo.State
          puts
        when "Kansas"
          @statePrecode = "17"
          print "Kansas PreCode Used for: ", @geo.State
          puts
        when "Kentucky"
          @statePrecode = "18"
          print "Kentucky PreCode Used for: ", @geo.State
          puts
        when "Louisiana"
          @statePrecode = "19"
          print "Louisiana PreCode Used for: ", @geo.State
          puts
        when "Maine"
          @statePrecode = "20"
          print "Maine PreCode Used for: ", @geo.State
          puts
        when "Maryland"
          @statePrecode = "21"
          print "Maryland PreCode Used for: ", @geo.State
          puts
        when "Massachusetts"
          @statePrecode = "22"
          print "Massachusetts PreCode Used for: ", @geo.State
          puts
        when "Michigan"
          @statePrecode = "23"
          print "Michigan PreCode Used for: ", @geo.State
          puts
        when "Minnesota"
          @statePrecode = "24"
          print "Minnesota PreCode Used for: ", @geo.State
          puts
        when "Mississippi"
          @statePrecode = "25"
          print "Mississippi PreCode Used for: ", @geo.State
          puts
        when "Missouri"
          @statePrecode = "26"
          print "Missouri PreCode Used for: ", @geo.State
          puts
        when "Montana"
          @statePrecode = "27"
          print "Montana PreCode Used for: ", @geo.State
          puts
        when "Nebraska"
          @statePrecode = "28"
          print "Nebraska PreCode Used for: ", @geo.State
          puts
        when "Nevada"
          @statePrecode = "29"
          print "Nevada PreCode Used for: ", @geo.State
          puts
        when "NewHampshire"
          @statePrecode = "30"
          print "NewHampshire PreCode Used for: ", @geo.State
          puts
        when "NewJersey"
          @statePrecode = "31"
          print "NewJersey PreCode Used for: ", @geo.State
          puts
        when "NewMexico"
          @statePrecode = "32"
          print "NewMexico PreCode Used for: ", @geo.State
          puts
        when "NewYork"
          @statePrecode = "33"
          print "NewYork PreCode Used for: ", @geo.State
          puts
        when "NorthCarolina"
          @statePrecode = "34"
          print "NorthCarolina PreCode Used for: ", @geo.State
          puts
        when "NorthDakota"
          @statePrecode = "35"
          print "NorthDakota PreCode Used for: ", @geo.State
          puts
        when "Ohio"
          @statePrecode = "36"
          print "Ohio PreCode Used for: ", @geo.State
          puts
        when "Oklahoma"
          @statePrecode = "37"
          print "Oklahoma PreCode Used for: ", @geo.State
          puts
        when "Oregon"
          @statePrecode = "38"
          print "Oregon PreCode Used for: ", @geo.State
          puts
        when "Pennsylvania"
          @statePrecode = "39"
          print "Pennsylvania PreCode Used for: ", @geo.State
          puts
        when "RhodeIsland"
          @statePrecode = "40"
          print "RhodeIsland PreCode Used for: ", @geo.State
          puts
        when "SouthCarolina"
          @statePrecode = "41"
          print "SouthCarolina PreCode Used for: ", @geo.State
          puts
        when "SouthDakota"
          @statePrecode = "42"
          print "SouthDakota PreCode Used for: ", @geo.State
          puts
        when "Tennessee"
          @statePrecode = "43"
          print "Tennessee PreCode Used for: ", @geo.State
          puts
        when "Texas"
          @statePrecode = "44"
          print "Texas PreCode Used for: ", @geo.State
          puts
        when "Utah"
          @statePrecode = "45"
          print "Utah PreCode Used for: ", @geo.State
          puts
        when "Vermont"
          @statePrecode = "46"
          print "Vermont PreCode Used for: ", @geo.State
          puts
        when "Virginia"
          @statePrecode = "47"
            print "Virginia PreCode Used for: ", @geo.State
            puts
        when "Washington"
          @statePrecode = "48"
          print "Washington PreCode Used for: ", @geo.State
          puts
        when "WestVirginia"
          @statePrecode = "49"
          print "WestVirginia PreCode Used for: ", @geo.State
          puts
        when "Wisconsin"
          @statePrecode = "50"
          print "Wisconsin PreCode Used for: ", @geo.State
          puts
        when "Wyoming"
          @statePrecode = "51"
          print "Wyoming PreCode Used for: ", @geo.State
          puts
    #      when "NotApplicable"
    #        @statePrecode = "52"
    #        print "NotApplicable PreCode Used for: ", @geo.State
    #        puts
        when "AmericanSamoa"
          @statePrecode = "53"
          print "AmericanSamoa PreCode Used for: ", @geo.State
          puts
        when "FederatedStatesofMicronesia"
          @statePrecode = "54"
          print "FederatedStatesofMicronesia PreCode Used for: ", @geo.State
          puts
        when "Guam"
          @statePrecode = "55"
          print "Guam PreCode Used for: ", @geo.State
          puts
        when "MarshallIslands"
          @statePrecode = "56"
          print "MarshallIslands PreCode Used for: ", @geo.State
          puts
        when "NorthernMarinaIslands"
          @statePrecode = "57"
          print "NorthernMarinaIslands PreCode Used for: ", @geo.State
          puts
        when "Palau"
          @statePrecode = "58"
          print "Palau PreCode Used for: ", @geo.State
          puts
        when "PuertoRico"
          @statePrecode = "59"
          print "PuertoRico PreCode Used for: ", @geo.State
          puts
        when "VirginIslands"
          @statePrecode = "60"
          print "VirginIslands PreCode Used for: ", @geo.State
          puts
        end # case
        
      end # if @geo = nil
      
    else
    end # if country = 9
        
    # Just in case user goes back to last qualification question and returns - this prevents the array from adding duplicates to previous list. Need to prevent back action across the board and then delete these to avaoid blank entries in these arrays.
    
    user.QualifiedSurveys = []
    user.SurveysWithMatchingQuota = []
    user.SupplierLink = []
    @fedSupplierLinks = Array.new

    # Lets find surveys that user is qualified for.
      
    # If this is a TEST e.g. with a network provider then route user to run the standard test survey.

    @netid = user.netid
    @poorconversion = false
      
    if Network.where(netid: @netid).exists? then
      net = Network.find_by netid: @netid
        
      if net.payout == nil then
        @currentpayout = 1.85 # assumes this is the minimum payout for FED surveys across networks including the 30% fees
      else
        @currentpayout = (1.44*net.payout).round(2) # FED CPI must be higher than net.payout + 30% of survey CPI. This approximation with 30% of net.payout is a good approximation.
        print '****************************** minimum payout for FED set to: ', @currentpayout
        puts
      end
             
             
      if (net.status == "EXTTEST") then
        puts "***********EXTTEST FOUND ***************"
        redirect_to '/users/techtrendssamplesurvey'
        return
      else
        if (net.status == "INACTIVE") then
          p '****************************** ACCESS FROM AN INACTIVE NETWOK DENIED'
          redirect_to '/users/nosuccess'
          return
        else
          if (net.status == "INTTEST") then
            @netstatus = "INTTEST"
          else
            if (net.status == "SAFETY") then
              @poorconversion = true
            else
              # MUST BE AN ACTIVE NETWORK -> Continue
              @poorconversion = false
              if net.Flag1 !=nil then
                if net.Flag1.to_i > 0 then
                  net.Flag1 = (net.Flag1.to_i - 1).to_s
                  net.save
                  redirect_to '/users/techtrendssamplesurvey'
                  return
                else
                end
              else
              end
            end
          end
        end
      end
    else
      # Bad netid, Network is not known
      p '****************************** ACCESS FROM AN UNRECOGNIZED NETWOK DENIED'
      redirect_to '/users/nosuccess'
      return
    end


    pulley_base_url = "https://pulley.samplicio.us/entry?"
    lid = user.country
    sid = "f162681e-268a-46af-906e-eb4443a4013a"
    pid = user.user_id
    loi = "not set"
    cos = @currentpayout.to_s
    tar = "not set"
    mid = "not set"


    if user.industries.empty? then
      @industriesvalue = '&643='
    else      
      @industriesvalue = '&643='+user.industries[0]
      if user.industries.length > 1 then
        (1..user.industries.length-1).each do |i|
          @industriesvalue = @industriesvalue+'&643='+user.industries[i]
        end
      else
      end
    end

    print '*****************>>>> Pulley Arguments: ', 'lid= ', lid, 'pid= ', pid, 'cos= ', cos
    puts


    if user.country=="9" then 
      @Pulley_AdditionalValues = '&42='+user.age+'&43='+user.gender+'&45='+user.ZIP+'&47='+user.ethnicity+'&113='+user.race+'&48741='+user.eduation+'&61076='+user.householdincome+'&2189='+user.employment+'&5729='+user.pindustry+'&15297='+user.jobtitle+'&96='+@statePrecode+'&97='+@DMARegionCode+@industriesvalue
      print '****AV9****>>>>>>', '&42=',user.age,'&43=',user.gender,'&45=',user.ZIP,'&47=',user.ethnicity,'&113=',user.race,'&48741=',user.eduation,'&61076=',user.householdincome,'&2189=',user.employment,'&5729=',user.pindustry,'&15297=',user.jobtitle,'&96=',@statePrecode,'&97=',@DMARegionCode,@industriesvalue, '******'
      puts
    else
      if user.country=="6" then
        @Pulley_AdditionalValues = '&42='+user.age+'&43='+user.gender+'&12345='+user.ZIP.slice(0..2)+'&48741='+user.eduation+'&61076='+user.householdincome+'&2189='+user.employment+'&5729='+user.pindustry+'&15297='+user.jobtitle+'&1015='+@provincePrecode+@industriesvalue
        print '******AV6****>>>>', '&42=',user.age,'&43=',user.gender,'&12345=',user.ZIP.slice(0..2),'&48741=',user.eduation,'&61076=',user.householdincome,'&2189=',user.employment,'&5729=',user.pindustry,'&15297=',user.jobtitle,'&1015=',@provincePrecode,@industriesvalue
        puts
      else
        if user.country=="5" then
          @Pulley_AdditionalValues = '&42='+user.age+'&43='+user.gender+'&12340='+user.ZIP+'&48741='+user.eduation+'&61076='+user.householdincome+'&2189='+user.employment+'&5729='+user.pindustry+'&15297='+user.jobtitle+@industriesvalue
          print '********AV5****>>', '&42=',user.age,'&43=',user.gender,'&12340=',user.ZIP,'&48741=',user.eduation,'&61076=',user.householdincome,'&2189=',user.employment,'&5729=',user.pindustry,'&15297=',user.jobtitle,@industriesvalue
          puts
        else
          if user.country=="7" then
            @Pulley_AdditionalValues = '&42='+user.age+'&43='+user.gender+'&12357='+user.ZIP+'&48741='+user.eduation+'&61076='+user.householdincome+'&2189='+user.employment+'&5729='+user.pindustry+'&15297='+user.jobtitle+@industriesvalue
            print '******AV7**>>>>>',  '&42=',user.age,'&43=',user.gender,'&12357=',user.ZIP,'&48741=',user.eduation,'&61076=',user.householdincome,'&2189=',user.employment,'&5729=',user.pindustry,'&15297=',user.jobtitle,@industriesvalue
            puts
          else
          end
        end
      end
    end


    baseLink = pulley_base_url+'lid='+lid+'&sid='+sid+'&pid='+pid+'&cos='+cos+@Pulley_AdditionalValues

    print "**************************** Puley baseLink = ", baseLink
    puts


    # Compute SHA-1 encryption for the baseLink and make it URL encoded
    @SHA1Signature = Base64.encode64((HMAC::SHA1.new(@SHA1key) << baseLink).digest).strip

    # Base-64 URL encode the Hash signature
    #    p 'Signature 1 =', @SHA1Signature  
    @SHA1Signature = @SHA1Signature.gsub '+', '%2B'
    #    p 'Signature 2 =', @SHA1Signature
    @SHA1Signature = @SHA1Signature.gsub '/', '%2F'
    #    p 'Signature 3 =', @SHA1Signature
    @SHA1Signature= @SHA1Signature.gsub '=', '%3D'
    #    p 'Signature 4 =', @SHA1Signature

    @fedSupplierLinks << baseLink+'&hash='+@SHA1Signature
    
    # Save the FED survey numbers that the user meets the qualifications and quota requirements for in this user's record of database in rank order
    
    user.save

    print "*********************************** FED SupplierLinks: ", @fedSupplierLinks
    puts
    
    print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++a ", user.user_id, " of ", user.country, " Time 3 End FED search: ", Time.now
    puts
    
    # Select Adhoc surveys next
    selectAdhocSurveys(session_id)        
  end # end rankfedsurveys

  def selectAdhocSurveys(session_id)
    
    require 'digest/hmac'
    require 'net/http'
    require 'uri'
    
    user=User.find_by session_id: session_id
    
    @adhocClient = Network.find_by name: "ADHOC"
    if (@adhocClient.status == "ACTIVE") then
      @adhocNetId = @adhocClient.netid
      print "**************** Assigned ADHOC @adhocNetId = ", @adhocNetId
      puts

      #Initialize an array to store qualified Adhoc surveys
      @adhocQualifiedSurveys = Array.new
      @adhocSurveysWithQuota = Array.new
      @adhocSupplierLinks = Array.new

      # Validate user network and get/set payout info.

      @netid = user.netid      
      if Network.where(netid: @netid).exists? then
        net = Network.find_by netid: @netid
          
        if net.payout == nil then
          @currentpayout = 1.25 # assumes this is the minimum payout of $1.25 across networks. There is no extra cost.
        else
          @currentpayout = net.payout
          print '****************************** minimum payout for ADHOC set to: ', @currentpayout
          puts
        end
      else
        # Bad netid, Network is not known
        p '****************************** ACCESS FROM AN UNRECOGNIZED NETWOK DENIED'
        redirect_to '/users/nosuccess'
        return
      end
      
      puts "**************************** STARTING SEARCH FOR ADHOC SURVEYS which USER QUALIFIES FOR"
      
      #Prints for testing code

      print '???????????????????????????????????------------------------>>>> Assumed instance variables Codes in ADHOC survey selection for Gender: ', @GenderPreCode, ' DMA: ', @DMARegionCode, ' State: ', @statePrecode, ' Region: ', @regionPrecode, ' Division: ',@divisionPrecode
      puts


      # change countrylanguageid setting to match user countryID only
      @usercountry = (user.country).to_i

      #Survey.where("CountryLanguageID = ? AND SurveyGrossRank >= ?", @usercountry, @topofstack).order( "SurveyGrossRank" ).each do |survey|
      Adhoc.where("CountryLanguageID = ? AND SurveyStillLive = ? AND CPI >= ?", @usercountry, true, @currentpayout).each do |survey|     
      #Adhoc.where("CPI >= ?", @currentpayout).each do |survey|      


        if (((survey.CountryLanguageID == 5) &&        
        #          ( survey.SurveyStillLive ) && 
          (( survey.QualificationAgePreCodes.empty? ) || ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([ user.age ] & survey.QualificationAgePreCodes.flatten) == [ user.age ] )) && 
          (( survey.QualificationGenderPreCodes.empty? ) || ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || ((@GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )) && 
          (( survey.QualificationZIPPreCodes.empty? ) || ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])) &&
          (( survey.QualificationRacePreCodes.empty? ) || ( survey.QualificationRacePreCodes.flatten == [ "ALL" ] ) || (([ user.race ] & survey.QualificationRacePreCodes.flatten) == [ user.race ])) &&
          (( survey.QualificationEthnicityPreCodes.empty? ) || ( survey.QualificationEthnicityPreCodes.flatten == [ "ALL" ] ) || (([ user.ethnicity ] & survey.QualificationEthnicityPreCodes.flatten) == [ user.ethnicity ])) &&
          (( survey.QualificationEducationPreCodes.empty? ) || ( survey.QualificationEducationPreCodes.flatten == [ "ALL" ] ) || (([ user.eduation ] & survey.QualificationEducationPreCodes.flatten) == [ user.eduation ])) &&
          (( survey.QualificationHHIPreCodes.empty? ) || ( survey.QualificationHHIPreCodes.flatten == [ "ALL" ] ) || (([ user.householdincome ] & survey.QualificationHHIPreCodes.flatten) == [ user.householdincome ])) &&
          (( survey.QualificationEmploymentPreCodes.empty? ) || ( survey.QualificationEmploymentPreCodes.flatten == [ "ALL" ] ) || (([ user.employment ] & survey.QualificationEmploymentPreCodes.flatten) == [ user.employment ])) &&
          (( survey.QualificationPIndustryPreCodes.empty? ) || ( survey.QualificationPIndustryPreCodes.flatten == [ "ALL" ] ) || (([ user.pindustry ] & survey.QualificationPIndustryPreCodes.flatten) == [ user.pindustry ])) &&     
          (( survey.QualificationJobTitlePreCodes.empty? ) || ( survey.QualificationJobTitlePreCodes.flatten == [ "ALL" ] ) || (([ user.jobtitle ] & survey.QualificationJobTitlePreCodes.flatten) == [ user.jobtitle ])) &&
          (( survey.QualificationChildrenPreCodes.empty? ) || ( survey.QualificationChildrenPreCodes.flatten == [ "ALL" ] ) || (( user.children & survey.QualificationChildrenPreCodes.flatten).empty? == false)) 
          #          &&
          #          (( survey.CPI == nil) || (survey.CPI >= @currentpayout)) 
          ) ||
          
          
          # I have removed .slice(0..2) in the Zip comparison - tripple check it that it is the right thing for Adhoc surveys
          
          ((survey.CountryLanguageID == 6) &&          
    #          ( survey.SurveyStillLive ) && 
          (( survey.QualificationAgePreCodes.empty? ) || ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([ user.age ] & survey.QualificationAgePreCodes.flatten) == [ user.age ] )) && 
          (( survey.QualificationGenderPreCodes.empty? ) || ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || ((@GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )) && 
          (( survey.QualificationZIPPreCodes.empty? ) || ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])) &&
          (( survey.QualificationRacePreCodes.empty? ) || ( survey.QualificationRacePreCodes.flatten == [ "ALL" ] ) || (([ user.race ] & survey.QualificationRacePreCodes.flatten) == [ user.race ])) &&
          (( survey.QualificationEthnicityPreCodes.empty? ) || ( survey.QualificationEthnicityPreCodes.flatten == [ "ALL" ] ) || (([ user.ethnicity ] & survey.QualificationEthnicityPreCodes.flatten) == [ user.ethnicity ])) &&
          (( survey.QualificationEducationPreCodes.empty? ) || ( survey.QualificationEducationPreCodes.flatten == [ "ALL" ] ) || (([ user.eduation ] & survey.QualificationEducationPreCodes.flatten) == [ user.eduation ])) &&
          (( survey.QualificationHHIPreCodes.empty? ) || ( survey.QualificationHHIPreCodes.flatten == [ "ALL" ] ) || (([ user.householdincome ] & survey.QualificationHHIPreCodes.flatten) == [ user.householdincome ])) &&
          (( survey.QualificationEmploymentPreCodes.empty? ) || ( survey.QualificationEmploymentPreCodes.flatten == [ "ALL" ] ) || (([ user.employment ] & survey.QualificationEmploymentPreCodes.flatten) == [ user.employment ])) &&
          (( survey.QualificationPIndustryPreCodes.empty? ) || ( survey.QualificationPIndustryPreCodes.flatten == [ "ALL" ] ) || (([ user.pindustry ] & survey.QualificationPIndustryPreCodes.flatten) == [ user.pindustry ])) &&     
          (( survey.QualificationJobTitlePreCodes.empty? ) || ( survey.QualificationJobTitlePreCodes.flatten == [ "ALL" ] ) || (([ user.jobtitle ] & survey.QualificationJobTitlePreCodes.flatten) == [ user.jobtitle ])) &&
          (( survey.QualificationChildrenPreCodes.empty? ) || ( survey.QualificationChildrenPreCodes.flatten == [ "ALL" ] ) || (( user.children & survey.QualificationChildrenPreCodes.flatten).empty? == false)) &&
          (( survey.QualificationHHCPreCodes.empty? ) || ( survey.QualificationHHCPreCodes.flatten == [ "ALL" ] ) || (([ @provincePrecode ] & survey.QualificationHHCPreCodes.flatten) == [ @provincePrecode ])) 
    #          &&
    #          (( survey.CPI == nil) || (survey.CPI >= @currentpayout)) 
          ) ||        
          
          ( (survey.CountryLanguageID == 9) &&          
    #          ( survey.SurveyStillLive ) && 
          (( survey.QualificationAgePreCodes.empty? ) || ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([ user.age ] & survey.QualificationAgePreCodes.flatten) == [ user.age ] )) && 
          (( survey.QualificationGenderPreCodes.empty? ) || ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || ((@GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )) && 
          (( survey.QualificationZIPPreCodes.empty? ) || ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])) &&
          (( survey.QualificationRacePreCodes.empty? ) || ( survey.QualificationRacePreCodes.flatten == [ "ALL" ] ) || (([ user.race ] & survey.QualificationRacePreCodes.flatten) == [ user.race ])) &&
          (( survey.QualificationEthnicityPreCodes.empty? ) || ( survey.QualificationEthnicityPreCodes.flatten == [ "ALL" ] ) || (([ user.ethnicity ] & survey.QualificationEthnicityPreCodes.flatten) == [ user.ethnicity ])) &&
          (( survey.QualificationEducationPreCodes.empty? ) || ( survey.QualificationEducationPreCodes.flatten == [ "ALL" ] ) || (([ user.eduation ] & survey.QualificationEducationPreCodes.flatten) == [ user.eduation ])) &&
          (( survey.QualificationHHIPreCodes.empty? ) || ( survey.QualificationHHIPreCodes.flatten == [ "ALL" ] ) || (([ user.householdincome ] & survey.QualificationHHIPreCodes.flatten) == [ user.householdincome ])) &&
          (( survey.QualificationEmploymentPreCodes.empty? ) || ( survey.QualificationEmploymentPreCodes.flatten == [ "ALL" ] ) || (([ user.employment ] & survey.QualificationEmploymentPreCodes.flatten) == [ user.employment ])) &&
          (( survey.QualificationPIndustryPreCodes.empty? ) || ( survey.QualificationPIndustryPreCodes.flatten == [ "ALL" ] ) || (([ user.pindustry ] & survey.QualificationPIndustryPreCodes.flatten) == [ user.pindustry ])) && 
          (( survey.QualificationJobTitlePreCodes.empty? ) || ( survey.QualificationJobTitlePreCodes.flatten == [ "ALL" ] ) || (([ user.jobtitle ] & survey.QualificationJobTitlePreCodes.flatten) == [ user.jobtitle ])) &&                    
          (( survey.QualificationChildrenPreCodes.empty? ) || ( survey.QualificationChildrenPreCodes.flatten == [ "ALL" ] ) || (( user.children  & survey.QualificationChildrenPreCodes.flatten).empty? == false)) &&                             
          (( survey.QualificationDMAPreCodes.empty? ) || ( survey.QualificationDMAPreCodes.flatten == [ "ALL" ] ) || (([ @DMARegionCode ] & survey.QualificationDMAPreCodes.flatten) == [ @DMARegionCode ])) && 
          (( survey.QualificationStatePreCodes.empty? ) || ( survey.QualificationStatePreCodes.flatten == [ "ALL" ] ) || (([ @statePrecode ] & survey.QualificationStatePreCodes.flatten) == [ @statePrecode ])) && 
          (( survey.QualificationRegionPreCodes.empty? ) || ( survey.QualificationRegionPreCodes.flatten == [ "ALL" ] ) || (([ @regionPrecode ] & survey.QualificationRegionPreCodes.flatten) == [ @regionPrecode ])) && 
          (( survey.QualificationDivisionPreCodes.empty? ) || ( survey.QualificationDivisionPreCodes.flatten == [ "ALL" ] ) || (([ @divisionPrecode ] & survey.QualificationDivisionPreCodes.flatten) == [ @divisionPrecode ])) 
    #          &&       
    #          (( survey.CPI == nil) || (survey.CPI >= @currentpayout)) 
          ))         
          
        then
          #Prints for testing code

          @_gender = ( survey.QualificationGenderPreCodes.empty? ) || ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (( @GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )
          @_age = ( survey.QualificationAgePreCodes.empty? ) || ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([user.age] & survey.QualificationAgePreCodes.flatten) == [user.age])
          @_age_value = [user.age] & survey.QualificationAgePreCodes.flatten
          @_race = (( survey.QualificationRacePreCodes.empty? ) || ( survey.QualificationRacePreCodes.flatten == [ "ALL" ] ) || (([ user.race ] & survey.QualificationRacePreCodes.flatten) == [ user.race ]))
          @_ethnicity= (( survey.QualificationEthnicityPreCodes.empty? ) || ( survey.QualificationEthnicityPreCodes.flatten == [ "ALL" ] ) || (([ user.ethnicity ] & survey.QualificationEthnicityPreCodes.flatten) == [ user.ethnicity ]))
          @_education= (( survey.QualificationEducationPreCodes.empty? ) || ( survey.QualificationEducationPreCodes.flatten == [ "ALL" ] ) || (([ user.eduation ] & survey.QualificationEducationPreCodes.flatten) == [ user.eduation ]))
          @_HHI= (( survey.QualificationHHIPreCodes.empty? ) || ( survey.QualificationHHIPreCodes.flatten == [ "ALL" ] ) || (([ user.householdincome ] & survey.QualificationHHIPreCodes.flatten) == [ user.householdincome ]))
          @_employment = (( survey.QualificationEmploymentPreCodes.empty? ) || ( survey.QualificationEmploymentPreCodes.flatten == [ "ALL" ] ) || (([ user.employment ] & survey.QualificationEmploymentPreCodes.flatten) == [ user.employment ]))
          @_pindustry = (( survey.QualificationPIndustryPreCodes.empty? ) || ( survey.QualificationPIndustryPreCodes.flatten == [ "ALL" ] ) || (([ user.pindustry ] & survey.QualificationPIndustryPreCodes.flatten) == [ user.pindustry ]))
          @_jobtitle = (( survey.QualificationJobTitlePreCodes.empty? ) || ( survey.QualificationJobTitlePreCodes.flatten == [ "ALL" ] ) || (([ user.jobtitle ] & survey.QualificationJobTitlePreCodes.flatten) == [ user.jobtitle ]))          
          @_children = (( survey.QualificationChildrenPreCodes.empty? ) || ( survey.QualificationChildrenPreCodes.flatten == [ "ALL" ] ) || (( user.children  & survey.QualificationChildrenPreCodes.flatten).empty? == false)) 
          @_children_logic = (user.children & survey.QualificationChildrenPreCodes.flatten)
         # @_industries = (( survey.QualificationIndustriesPreCodes.empty? ) || ( survey.QualificationIndustriesPreCodes.flatten == [ "ALL" ] ) || (( user.industries & survey.QualificationIndustriesPreCodes.flatten).empty? == false))
         # @_industries_logic = ( user.industries & survey.QualificationIndustriesPreCodes)
          @_CPI_check = ((survey.CPI == nil) || (survey.CPI >= @currentpayout))
          

          puts "---------------------------------->>>  Replace QualificationHHCPrecodes with CA_provincePrecodes column"
        
          print '************ Adhoc User QUALIFIED for survey number = ', survey.SurveyNumber, ' RANK= ', survey.SurveyGrossRank, ' User enetered Gender: ', @GenderPreCode, ' Gender from Survey= ', survey.QualificationGenderPreCodes, ' USER ENTERED AGE= ', user.age, ' AGE PreCodes from Survey= ', survey.QualificationAgePreCodes, ' User Entered ZIP: ', user.ZIP, ' ZIP PreCodes from Survey: ..... ', ' User Entered Race: ', user.race, ' Race PreCode from survey: ', survey.QualificationRacePreCodes, ' User Entered ethnicity: ', user.ethnicity, ' Ethnicity PreCode from survey: ', survey.QualificationEthnicityPreCodes, ' User Entered education: ', user.eduation, ' Education PreCode from survey: ', survey.QualificationEducationPreCodes, ' User Entered HHI: ', user.householdincome, ' HHI PreCode from survey: ', survey.QualificationHHIPreCodes, ' User Entered Employment: ', user.employment, ' Std_Employment PreCode from survey: ', survey.QualificationEmploymentPreCodes, ' User Entered PIndustry: ', user.pindustry, ' PIndustry PreCode from survey: ', survey.QualificationPIndustryPreCodes, ' User Entered JobTitle: ', user.jobtitle, ' JobTitle PreCode from survey: ', survey.QualificationJobTitlePreCodes, ' User Entered Children: ', user.children, ' Children PreCodes from survey: ', survey.QualificationChildrenPreCodes, ' User Entered Industries: ', user.industries, ' Industries PreCodes from survey: ....', ' Network Payout: ', @currentpayout, ' CPI from survey: ', survey.CPI, ' SurveyStillAlive: ', survey.SurveyStillLive
         
          puts
          
          print '************* Adhoc Gender match: ', @_gender, ' Age match: ', @_age, ' Age_logic value: ', @_age_value, ' Race match: ', @_race, ' Ethnicity match: ', @_ethnicity, ' Education match: ', @_education, ' HHI match: ', @_HHI, ' Employment match: ', @_employment, ' PIndustry match: ', @_pindustry, ' JobTitle match: ', @_jobtitle, ' Children match: ', @_children, ' Children_logic value: ', @_children_logic,  ' Industries match: ', @_industries, ' Industries_logic value: ', @_industries_logic, ' CPI check: ', @_CPI_check
          puts
          

          if (survey.CountryLanguageID == 9) then
            @_ZIP = ( survey.QualificationZIPPreCodes.empty? ) || ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
            @_DMA = (( survey.QualificationDMAPreCodes.empty? ) || ( survey.QualificationDMAPreCodes.flatten == [ "ALL" ] ) || (([ @DMARegionCode ] & survey.QualificationDMAPreCodes.flatten) == [ @DMARegionCode ]))
            @_State = (( survey.QualificationStatePreCodes.empty? ) || ( survey.QualificationStatePreCodes.flatten == [ "ALL" ] ) || (([ @statePrecode ] & survey.QualificationStatePreCodes.flatten) == [ @statePrecode ]))
            @_region = (( survey.QualificationRegionPreCodes.empty? ) || ( survey.QualificationRegionPreCodes.flatten == [ "ALL" ] ) || (([ @regionPrecode ] & survey.QualificationRegionPreCodes.flatten) == [ @regionPrecode ]))
            @_Division = (( survey.QualificationDivisionPreCodes.empty? ) || ( survey.QualificationDivisionPreCodes.flatten == [ "ALL" ] ) || (([ @divisionPrecode ] & survey.QualificationDivisionPreCodes.flatten) == [ @divisionPrecode ]))                  
            
            # print '*********** Adhoc User Entered ZIP: ', user.ZIP, ' ZIP PreCodes from Survey: ', survey.QualificationZIPPreCodes, 'DMA from DB: ', @DMARegionCode, ' DMA from Survey: ', survey.QualificationDMAPreCodes, 'Region from DB: ', @regionPrecode, ' Region from Survey: ', survey.QualificationRegionPreCodes, 'Division from DB: ', @divisionPrecode, ' Division from Survey: ', survey.QualificationDivisionPreCodes
            # puts          
            
            print '************** Adhoc ZIP match: ', @_ZIP, ' DMA match: ', @_DMA, ' State match: ', @_State, ' Region match: ', @_region, ' Division match: ', @_Division
            puts
          else
          end
          
          if (survey.CountryLanguageID == 6) then
            #@_ZIP = ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP.slice(0..2) ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP.slice(0..2) ])
            @_ZIP = (( survey.QualificationZIPPreCodes.empty? ) || survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
            @_province_check = (( survey.QualificationHHCPreCodes.empty? ) || ( survey.QualificationHHCPreCodes.flatten == [ "ALL" ] ) || (([ @provincePrecode ] & survey.QualificationHHCPreCodes.flatten) == [ @provincePrecode ]))
            
            print '************** Adhoc ZIP slice match: ', @_ZIP, 'CA Province match: ', @_province_check
            puts
          else
          end
          
          
          @adhocSupplierLinks << survey.SupplierLink+@adhocNetId+survey.SurveyNumber.to_s+user.user_id
          
          print '********** Adhoc This USER_ID: ', user.user_id, ' has QUALIFIED for the following Adhoc survey : ', survey.SurveyNumber
          puts
          
          print '********** Adhoc In total This USER_ID: ', user.user_id, ' has created for the following survey Links: ', @adhocSupplierLinks
          puts
              
        else
          # No qualified Adhoc surveys found for if qualification conditions
          print '???????????????????????????????????------------------------>>>> NO QUALIFIED ADHOC SURVEYS FOUND **************'
          puts
        end

      end # do loop for all Adhoc surveys in db

    else
      print "***************** Adhoc surveys are not ACTIVE ************************"
      puts
    end # If Adhoc surveys are ACTIVE

    # Select RFG projects next
    selectRfgProjects(session_id)      
  end # end selectAdhocSurveys
  
  def selectRfgProjects(session_id)
    
    require 'digest/hmac'
    require 'net/http'
    require 'uri'
    
    apid = "54ef65c3e4b04d0ae6f9f4a7"
    secret = "8ef1fe91d92e0602648d157f981bb934"
    
    user=User.find_by session_id: session_id
    
    @RFGclient = Network.find_by name: "RFG"
    if (@RFGclient.status == "ACTIVE") then
      @rid = @RFGclient.netid+user.user_id
    
      print "**************** Assigned RFG @rid = ", @rid
      puts
        
      if user.age != nil then
        @RFGbirthday = (Time.now.year.to_i - user.age.to_i).to_s + "-" + (Random.rand(11)+1).to_s + "-" + (Random.rand(27)+1).to_s
        # print "-----RFGbirthday-------------------***************__________________", @RFGbirthday
        # puts
      else
        @RFGbirthday = "0"
      end
       
      if user.employment == nil then
        @RFGEmployment = '0'
      else
        @RFGEmployment = user.employment
      end

      # print "----RFGEmployment--------------------***************__________________", @RFGEmployment
      # puts

      if user.eduation == nil then
        @RFGEducation = '0'
      else
        if user.eduation == "-3105" then
          @RFGEducation = '9'
        else
          @RFGEducation = user.eduation
        end
      end
        
      # print "----RFGEducation -------------------***************__________________", @RFGEducation
      # puts 
      
      if (user.race == nil) then
        @RFGEthnicity = '0'
      else
        @RFGEthnicity = user.race
      end 
      
      # print "----RFGEthnicity--------------------***************__________________", @RFGEthnicity
      # puts

      if user.householdincome == nil then
        @RFGHhi = '0'
      else
        if user.householdincome == '-3105' then
           @RFGHhi = "9" 
        else
          @RFGHhi = user.householdincome
        end
      end

      # print "----RFGHhi -------------------***************__________________", @RFGHhi
      # puts 

      if user.jobtitle == nil then
        @RFGJobTitle = '0'
      else
        @RFGJobTitle = user.jobtitle
      end

      # print "----RFGJobTitle -------------------***************__________________", @RFGJobTitle
      # puts 

      if user.pindustry == nil then
        @RFGPindustry = '0'
      else
        case user.pindustry.to_i
        when 1
          @RFGPindustry = "1"
        when 2
          @RFGPindustry = "2"
        when 3
          @RFGPindustry = "4"
        when 4
          @RFGPindustry = "5"
        when 5
          @RFGPindustry = "8"        
        when 6
          @RFGPindustry = "9"
        when 7
          @RFGPindustry = "10"
        when 8
          @RFGPindustry = "12"
        when 9
          @RFGPindustry = "13"
        when 10
          @RFGPindustry = "15"
        when 11
          @RFGPindustry = "16"
        when 12
          @RFGPindustry = "17"
        when 13
          @RFGPindustry = "18"
        when 14
          @RFGPindustry = "19"
        when 15
          @RFGPindustry = "20"
        when 16
          @RFGPindustry = "21"
        when 17
          @RFGPindustry = "22"
        when 18
          @RFGPindustry = "23"
        when 19
          @RFGPindustry = "24"
        when 20
          @RFGPindustry = "26"
        when 21
          @RFGPindustry = "59"
        when 22
          @RFGPindustry = "28"
        when 23
          @RFGPindustry = "29"
        when 24
          @RFGPindustry = "31"
        when 25
          @RFGPindustry = "33"
        when 26
          @RFGPindustry = "34"
        when 27
          @RFGPindustry = "35"
        when 28
          @RFGPindustry = "36"
        when 29
          @RFGPindustry = "37"
        when 30
          @RFGPindustry = "39"
        when 31
          @RFGPindustry = "40"
        when 32
          @RFGPindustry = "41"
        when 33
          @RFGPindustry = "42"
        when 34
          @RFGPindustry = "43"
        when 35
          @RFGPindustry = "44"
        when 36
          @RFGPindustry = "45"
        when 37
          @RFGPindustry = "46"
        when 38
          @RFGPindustry = "47"
        when 39
          @RFGPindustry = "48"
        when 40
          @RFGPindustry = "49"
        when 41
          @RFGPindustry = "50"
        when 42
          @RFGPindustry = "51"
        when 43
          @RFGPindustry = "17"
        when 44
          @RFGPindustry = "52"
        when 45
          @RFGPindustry = "54"
        when 46
          @RFGPindustry = "55"
        when 47
          @RFGPindustry = "62"
        when 48
          @RFGPindustry = "58"
        when 49
          @RFGPindustry = "57"
        when 50
          @RFGPindustry = "63"
        when 51
          @RFGPindustry = "64"
        end
      end

      # print "----RFGPindustry -------------------***************__________________", @RFGPindustry
      # puts


      @parsed_user_agent = UserAgent.parse(user.user_agent)
      if @parsed_user_agent.platform == 'iPhone' then
        @isMobileDevice = "Yes"
        p "*************************************** RankRFGProjects: isMobileDevice is set YES"
      else
        @isMobileDevice = "No"
        p "*************************************** RankRFGProjects: isMobileDevice is set NO"  
      end
        
      if user.country=="9" then 
        @RFGAdditionalValues = '&rid='+@rid+'&country=US'+'&postalCode='+user.ZIP+'&gender='+user.gender+'&birthday='+@RFGbirthday+'&rfg2_48741='+@RFGEducation+'&rfg2_61076='+@RFGHhi+'&rfg2_2189='+@RFGEmployment+'&rfg2_15297='+@RFGJobTitle+'&employmentIndustry='+@RFGPindustry+'&isMobileDevice='+@isMobileDevice+'&rfg2_113='+@RFGEthnicity
      else
        if user.country=="6" then
            @RFGAdditionalValues = '&rid='+@rid+'&country=CA'+'&postalCode='+user.ZIP+'&gender='+user.gender+'&birthday='+@RFGbirthday+'&rfg2_48741='+@RFGEducation+'&rfg2_61076='+@RFGHhi+'&rfg2_2189='+@RFGEmployment+'&rfg2_15297='+@RFGJobTitle+'&employmentIndustry='+@RFGPindustry+'&isMobileDevice='+@isMobileDevice
        else
          if user.country=="5" then
              @RFGAdditionalValues = '&rid='+@rid+'&country=AU'+'&postalCode='+user.ZIP+'&gender='+user.gender+'&birthday='+@RFGbirthday+'&rfg2_48741='+@RFGEducation+'&rfg2_61076='+@RFGHhi+'&rfg2_2189='+@RFGEmployment+'&rfg2_15297='+@RFGJobTitle+'&employmentIndustry='+@RFGPindustry+'&isMobileDevice='+@isMobileDevice
          else
          end
        end
      end

      # Instead of LiveLink use Offerwall surveys

      p "******* DEBUG: *********>>>>>>>>>> RFG Offerwall API call with params <<<<<<<<*******FAILS IF CLOCK OUT OF SYNC-----------"

      if user.country=="9" then
        command = { :command => "offerwall/query/1", :rid => @rid, :country => "US", :fingerprint => user.fingerprint, :ip => user.ip_address, :postalCode => user.ZIP, :gender => user.gender, :birthday => @RFGbirthday, :rfg2_61076 => @RFGHhi, :rfg2_2189 => @RFGEmployment, :rfg2_48741 => @RFGEducation, :rfg2_15297 => @RFGJobTitle, :employmentIndustry => @RFGPindustry, :isMobileDevice => @isMobileDevice, :type => 1, :rfg2_113 => @RFGEthnicity}.to_json
      else
        if user.country=="6" then
          command = { :command => "offerwall/query/1", :rid => @rid, :country => "CA", :fingerprint => user.fingerprint, :ip => user.ip_address, :postalCode => user.ZIP, :gender => user.gender, :birthday => @RFGbirthday, :rfg2_61076 => @RFGHhi, :rfg2_2189 => @RFGEmployment, :rfg2_48741 => @RFGEducation, :rfg2_15297 => @RFGJobTitle, :employmentIndustry => @RFGPindustry, :isMobileDevice => @isMobileDevice, :type => 1}.to_json
        else
          if user.country=="5" then
        command = { :command => "offerwall/query/1", :rid => @rid, :country => "AU", :fingerprint => user.fingerprint, :ip => user.ip_address, :postalCode => user.ZIP, :gender => user.gender, :birthday => @RFGbirthday, :rfg2_61076 => @RFGHhi, :rfg2_2189 => @RFGEmployment, :rfg2_48741 => @RFGEducation, :rfg2_15297 => @RFGJobTitle, :employmentIndustry => @RFGPindustry, :isMobileDevice => @isMobileDevice, :type => 1}.to_json          
          else
          end
        end
      end

      print "RFG Offerwall Command: ", command
      puts

      time=Time.now.to_i
      hash = Digest::HMAC.hexdigest("#{time}#{command}", secret.scan(/../).map {|x| x.to_i(16).chr}.join, Digest::SHA1)
      uri = URI("https://www.saysoforgood.com/API?apid=#{apid}&time=#{time}&hash=#{hash}")
    
      begin
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          req = Net::HTTP::Post.new uri
          req.body = command
          req.content_type = 'application/json'
          response = http.request req
          @OfferwallResponse = JSON.parse(response.body)  
        end
            
        rescue Net::ReadTimeout => e  
        puts e.message
      end

      # print "Offerwall Response: ", @OfferwallResponse["response"]
      # puts

      if @OfferwallResponse["response"]["surveys"].length == 0 then
        print "*********No surveys returned by RFG Offerwall**********"
        puts
        @RFGSupplierLinks = []
      else
        # @maxIRIndex = 0
        # @maxIR = @OfferwallResponse["response"]["surveys"][@maxIRIndex]["ir"]
        # @RFGOfferwallSupplierLink = @OfferwallResponse["response"]["surveys"][0]["offer_url"]

        # @NumberOfSurveys = @OfferwallResponse["response"]["surveys"].length
          
        # print "************ Number of surveys on RFG Offerwall: ", @NumberOfSurveys
        # puts

        # # Pick RFG survey that has the highest IR and payout more than users net_payout.

        # user_net = Network.find_by netid: user.netid
        # @net_payout = "$"+user_net.payout.to_s
        
        # (0..@NumberOfSurveys-1).each do |i|
        #   if ((@maxIR < @OfferwallResponse["response"]["surveys"][i]["ir"]) && (@net_payout < @OfferwallResponse["response"]["surveys"][i]["payout"])) then
        #   # if @maxIR < @OfferwallResponse["response"]["surveys"][i]["ir"] then
        #     @maxIRIndex = i
        #     @maxIR = @OfferwallResponse["response"]["surveys"][i]["ir"]
        #     @RFGOfferwallSupplierLink = @OfferwallResponse["response"]["surveys"][i]["offer_url"]
        #   else
        #   end
        # end
        
        # print "***** DEBUG ******** Chosen RFG Offerwall SupplierLink: ", @RFGOfferwallSupplierLink, " at index: ", @maxIRIndex, " with IR: ", @maxIR, " and payout: ", @OfferwallResponse["response"]["surveys"][@maxIRIndex]["payout"]
        # puts

        @maxCRIndex = 0
        @maxCR = @OfferwallResponse["response"]["surveys"][@maxCRIndex]["projectCR"]
        @RFGOfferwallSupplierLink = @OfferwallResponse["response"]["surveys"][@maxCRIndex]["offer_url"]
        @NumberOfSurveys = @OfferwallResponse["response"]["surveys"].length
          
        print "****DEBUG******** Number of surveys on RFG Offerwall: ", @NumberOfSurveys
        puts

        print "*****DEBUG******* @maxCR initialized to: ", @maxCR
        puts

        print "****DEBUG******** @RFGOfferwallSupplierLink initialized to: ", @RFGOfferwallSupplierLink
        puts

        # Pick RFG survey that has the highest CR and payout more than users net_payout.

        user_net = Network.find_by netid: user.netid
        @net_payout = "$"+user_net.payout.to_s
        
        (0..@NumberOfSurveys-1).each do |i|
          if ((@maxCR < @OfferwallResponse["response"]["surveys"][i]["projectCR"]) && (@net_payout < @OfferwallResponse["response"]["surveys"][i]["payout"])) then
          # if @maxCR < @OfferwallResponse["response"]["surveys"][i]["ir"] then
            @maxCRIndex = i
            @maxCR = @OfferwallResponse["response"]["surveys"][i]["projectCR"]
            @RFGOfferwallSupplierLink = @OfferwallResponse["response"]["surveys"][i]["offer_url"]
          else
          end
        end
        
        print "***** DEBUG ******** Chosen RFG Offerwall SupplierLink: ", @RFGOfferwallSupplierLink, " at index: ", @maxCRIndex, " with projectCR: ", @maxCR, " and payout: ", @OfferwallResponse["response"]["surveys"][@maxCRIndex]["payout"], " and IR: ", @OfferwallResponse["response"]["surveys"][@maxCRIndex]["ir"]
        puts


        @RFGSupplierLinks = []
        @RFGSupplierLinks << @RFGOfferwallSupplierLink+@RFGAdditionalValues

        print "**** DEBUG ********>>>> User will be sent to this RFG link >>>>>>>>>>>>>>>>>>>>>>>>>0000ooooooooppppppp ", @RFGSupplierLinks,  "***************************************************************"
        puts      
      end   
    else
    # do nothing for RFG
    end # RFG status is ACTIVE / OFF
    
    # print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++a ", user.user_id, " of ", user.country, " Time-4 End RFG selection: ", Time.now
    # puts
    
    # Select P2S surveys next
    selectP2SSurveys (session_id)    
    # redirect_to '/users/moreSurveys'
  end #selectRfgProjects

  def selectP2SSurveys (session_id)
    # def userride (session_id)
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    
    user = User.find_by session_id: session_id
    # @PID = user.user_id

    # Queue up additional surveys from P2S. First calculate the additional values to be attached.
    
    @netid = user.netid  
    @net = Network.find_by netid: @netid
    
    if (user.country == '9') then
      if @net.P2S_US == 1 then
        @P2SisAttached = true
      else
        @P2SisAttached = false
      end
    else
    end
  
    if (user.country == '6') then
      if @net.P2S_CA == 1 then
        @P2SisAttached = true
      else
        @P2SisAttached = false
      end
    else
    end
    
    if (user.country == '5') then
      if @net.P2S_AU == 1 then
        @P2SisAttached = true
      else
        @P2SisAttached = false
      end
    else
    end   
    
    if (@P2SisAttached) then
      @P2Sclient = Network.find_by name: "P2S"
      @SUBID = @P2Sclient.netid+user.user_id
    
      print "**************** P2S @SUBID = ", @SUBID
      puts

      if user.gender == '1' then
        @p2s_gender = "m"
      else
        @p2s_gender = "f"
      end
             
      
      p2s_hispanic = [0, 6729, 6730, 6898, 6900, 6901, 6902, 6903, 6904, 6905, 6906, 6907, 6908, 6909, 6910, '']
      @p2s_hispanic = p2s_hispanic[user.ethnicity.to_i].to_s
      
      p2s_employment_status = [0, 7007, 7008, 7006, 7006, 7013, 7013, 7012, 7011, 7009, 7010, 23562, '']
      @p2s_employment_status = p2s_employment_status[user.employment.to_i].to_s
      
      
      p2s_income_level = [0, 9089, 9089, 9089, 9071, 9072, 9088, 9073, 9087, 9074, 9086, 9090, 9075, 9091, 9076, 9092, 9077, 9093, 9078, 9094, 9079, 9080, 9081, 9082, 9085, 9084, 9084, '']
      @p2s_income_level = p2s_income_level[user.householdincome.to_i].to_s
      
      
      p2s_race = [0, 10094, 10095, 10101, 10097, 10098, 10104, 10109, 10110, 10111, 10096, 10102, 10106, 10107, 10108, 10103, '']
      @p2s_race = p2s_race[user.race.to_i].to_s
      
      p2s_education_level = [0, 10157, 10158, 10163, 10159, 10160, 10161, 10162, 10164, '']
      @p2s_education_level = p2s_education_level[user.eduation.to_i].to_s
      
      p2s_org_id = [0, 22942, 22934, '', '', 22936, '', 22942, '', '', 22938, '', 22957, 22957, 22957, 22957, 22938, '', '', 22939, 22940, 3650829, '', '', '', '', 22943, 22944, 22945, '', 22957, 3651719, '', 22946, 22947, 22949, 22948, 22950, '', 22952, '', 22944, 22953, '', 22954, '', '', '', '', '', 3661207, '']
      @p2s_org_id = p2s_org_id[user.pindustry.to_i].to_s
      
      p2s_jobtitle = [0, 3673669, 367670, 3673663, 3673668, 3673671, 3673675, 3673675, 3673672, 3673673, 3673674, 3673675]
      @p2s_jobtitle = p2s_jobtitle[user.jobtitle.to_i].to_s
       
      p2s_children = [0, 6971, 6972, 6971, 6972, 6973, 6974, 6975, 6976, 6977, 6978, 6979, 6980, 6981, 6982, 6983, 6984, 6985, 6986, 6987, 6988, 6989, 6990, 6991, 6992, 6993, 6994, 6995, 6996, 6997, 6998, 6999, 7000, 7001, 7002, 7003, 7004]
      
      
      if user.children != nil then
        if user.children[0] != '-3105' then
          @p2s_children = p2s_children[user.children[0].to_i].to_s
          
          if user.children.length > 1 then            
            (1..user.children.length-1).each do |i|
            
              if p2s_children[user.children[i].to_i] != '' then                  
                @p2s_children = @p2s_children+','+p2s_children[user.children[i].to_i].to_s    
              else
              end              
                
            end        
          else
          end
        else
          @p2s_children = '7005'
        end        
      else
        @p2s_children = ''
      end
      
      p2s_province = [0, 20509, 20508, 20511, 20515, 20517, 20519, 20516, 20520, 20512, 20514, 20513, 20510, 20518]
      @p2s_province = p2s_province[@provincePrecode.to_i].to_s
      
      

      # p2s additional values

      if user.country=="9" then
        @p2s_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP+'&employment_status='+@p2s_employment_status+'&income_level='+@p2s_income_level+'&education_level='+@p2s_education_level+'&hispanic='+@p2s_hispanic+'&race='+@p2s_race+'&org_id='+@p2s_org_id+'&job_title='+@p2s_jobtitle+'&children_under_18='+@p2s_children
      else
        if user.country=="6" then
          @p2s_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP+'&employment_status='+@p2s_employment_status+'&education_level='+@p2s_education_level+'&org_id='+@p2s_org_id+'&job_title='+@p2s_jobtitle+'&children_under_18='+@p2s_children+'&canada_regions='+@p2s_province
        else
          if user.country=="5" then
            @p2s_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP+'&employment_status='+@p2s_employment_status+'&education_level='+@p2s_education_level+'&org_id='+@p2s_org_id+'&job_title='+@p2s_jobtitle+'&children_under_18='+@p2s_children
          else
          end
        end
      end  
      
      #p2s hmac(md5) calculation
      
      p2ssecretkey = '9df95db5396d180e786c707415203b95'      
      @hmac = HMAC::MD5.new(p2ssecretkey).update(@p2s_AdditionalValues).hexdigest

      #p2s supplier link
      @p2sSupplierLink = ""
      @p2sSupplierLink = 'http://www.your-surveys.com/?si=55&ssi='+@SUBID+'&'+@p2s_AdditionalValues+'&hmac='+@hmac
      
      print "**************P2S SupplierLink = ", @p2sSupplierLink
      puts

       # THIS LINE BELOW CAN BE DELETED AS THE SECTION ELOW RESETS IT CORRECTLY.
      
      # user.SupplierLink << @p2sSupplierLink

      # Save the list of SupplierLinks with P2S, if ACTIVE
    
      user.save
      userride (session_id)
    else
      puts "-------------------********************** P2S is not attached ********************------------------------"
      userride (session_id)
    end #if P2SisAttached
  end # selectP2SSurveys

  def selectInnovateSurveys (session_id)
    # tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    # @innovateNetId = "4444"
    # @innovateSupplierLink = ""
    # @innovateSupplierLink = "http://innovate.go2cloud.org/aff_c?offer_id=821&aff_id=273&source=273&aff_sub="+@innovateNetId+user.user_id
  end

  def userride (session_id)

    user = User.find_by session_id: session_id

    @netid = user.netid  
    @net = Network.find_by netid: @netid


    # If user is blacklisted, then qterm
    if user.black_listed == true then
      print '******************** Userride: UserID is BLACKLISTED: ', user.user_id
      puts
      tracker.track(user.ip_address, 'NS_BL')
      redirect_to '/users/nosuccess'
      return
    else
    end

    # First order surveys by stackOrder for the user ride

    user.SupplierLink=[]
    (0..@net.stackOrder.length-1).each do |i|
      supplier = @net.stackOrder[i]      
      case supplier
      when "A"
        if @adhocSupplierLinks.length != 0 then
          user.SupplierLink = user.SupplierLink + @adhocSupplierLinks
        else
        end
      when "F"
        if @fedSupplierLinks.length !=0 then
          user.SupplierLink = user.SupplierLink + @fedSupplierLinks
        else
        end
      when "R"
        if @RFGSupplierLinks.length != 0 then
          user.SupplierLink = user.SupplierLink + @RFGSupplierLinks
        else
        end
      when "P"
        if [@p2sSupplierLink].length !=0 then
          user.SupplierLink = user.SupplierLink + [@p2sSupplierLink]
        else
        end
      when "I"
        if [@innovateSupplierLink].length !=0 then
          user.SupplierLink = user.SupplierLink + [@innovateSupplierLink]
        else
        end
      when "2"

          #if (user.emailid.empty? == false) then
          # add link to pleasewait which should call 
          # selectP2SPullAPISurveys (session_id) else

          user.SupplierLink = user.SupplierLink + ['/users/moreSurveys']
      end # case
    end # do
    
    # Remove any blank entries
    if user.SupplierLink !=nil then
      user.SupplierLink.reject! { |c| c == nil}
    else
    end

    print "************ After removing blank entries, user will be sent to these surveys: ", user.SupplierLink
    puts


    # Start the user ride
    
    if user.SupplierLink.length == 0 then

      if user.netid == "MMq0514UMM20bgf17Yatemoh" then
        redirect_to '/users/nosuccessPanelist'
      else
        redirect_to '/users/nosuccess'
      end

    else      

      # if user.SupplierLink[0] == @p2sSupplierLink then
      
      #   print '*************** User will be sent to P2S router as no other surveys are available: ', user.SupplierLink[0]
      #   puts
      if user.SupplierLink.length == 1 then
      
        print '*************** User will be sent to the only router in stackOrder as no other surveys are available: ', user.SupplierLink[0]
        puts
      
        @EntryLink = user.SupplierLink[0]
        user.SupplierLink = user.SupplierLink.drop(1)
        user.save
        redirect_to @EntryLink
      
      else
    
        # check if it is a Adhoc survey with screener questions
        
        @EntryLink = user.SupplierLink[0]        
        #@EntryLink = user.SupplierLink[0]+@PID+@AdditionalValues

        @adhocNetId = '1111' # replace with call to the Network dbase table
        if @EntryLink.include? '='+@adhocNetId then
          @ParsedEntryLink = @EntryLink.partition ("="+@adhocNetId) # adhocNetId is '1111'
          @adhocSurveyNumber = @ParsedEntryLink[2][0..3]  # Will stop working if SurveyNumber is not 4 digits

          print "************************ AdhocSurveyNumber in SupplierLink is: ", @adhocSurveyNumber, " *******************"
          puts

          user.SurveysAttempted << @adhocSurveyNumber
          user.save

          # Verify if user passes Screeners, if any, for this ADHOC survey
          @adhocSurvey = Adhoc.where("SurveyNumber = ?", @adhocSurveyNumber).first
          if @adhocSurvey.Screener1 != nil then

            print "lllllllllllllllll This adhoc survey has a screener1 ", @adhocSurveyNumber, " lllllll Redirecting user to screener llllllllll"
            puts

            redirect_to '/users/Scrnr1'
          else

            print "***************** Adhoc survey without Screener => User will be sent to this @EntryLink: ", @EntryLink
            puts
            user.SupplierLink = user.SupplierLink.drop(1)
            user.save
            redirect_to @EntryLink
          end
        else
          print "***************** Not an ADHOC survey => User will be sent to this @EntryLink: ", @EntryLink
          puts
          user.SupplierLink = user.SupplierLink.drop(1)
          user.save
          redirect_to @EntryLink
        end
      end # if user.SupplierLink[0] == @p2sSupplierLink then
    end # if user.SupplierLink.length == 0    
  end # userride

  def Scrnr1Action
    session_id = session.id
    user = User.find_by session_id: session_id

    #    tracker.track(user.ip_address, 'Scrnr1Action')
    @EntryLink = user.SupplierLink[0]
    if params[:Scrnr1Resp] != nil

      # sometimes users might go back on Scrn1 response
      if (user.SurveysAttempted[-1] == "1") || (user.SurveysAttempted[-1] == "2") then # this means the user has simply gone back => replace response
        user.SurveysAttempted[-1] = params[:Scrnr1Resp] # replace old response
      else
        user.SurveysAttempted << params[:Scrnr1Resp] # it is a first time response
      end

      user.save
      @adhocSurveyLookup = Adhoc.where("SurveyNumber = ?", user.SurveysAttempted[-2]).first # Is it always -2? NO, when there are 
    #CHANGE ---- more than 1 SreenerResponses are stored
      
      if @adhocSurveyLookup.Screener1Resp == params[:Scrnr1Resp] then
        #redirect_to '/users/Scrnr2'
        # Check if there are Additional questions
        if @adhocSurveyLookup.Pii1 != nil then
          redirect_to '/users/Pii1'
        else
          user.SupplierLink = user.SupplierLink.drop(1)
          user.save
          redirect_to @EntryLink
        end
      else
        # user disqualified from this ADHOC survey

        print '***************** User screened out from ADHOC survey: ', user.SupplierLink[0]
        puts

        user.SupplierLink = user.SupplierLink.drop(1)
        user.save
        checkNextSurveyAfterAdhoc (session_id)
      end
    else
      redirect_to '/users/Scrnr1' # Go back to same Scrnr1 question due to No user response
    end
  end
    
  def checkNextSurveyAfterAdhoc (session_id)
        
    user = User.find_by session_id: session_id    
    
    @EntryLink = user.SupplierLink[0]        
    #@EntryLink = user.SupplierLink[0]+@PID+@AdditionalValues
    
    print '***************** User will be sent to this @EntryLink: ', @EntryLink
    puts

    # Verify if user passes Screeners, if any, for this ADHOC survey

    @adhocNetId = '1111' # replace with call to the Network dbase table
      if @EntryLink.include? '='+@adhocNetId then
      @ParsedEntryLink = @EntryLink.partition ("="+@adhocNetId) # adhocNetId is '1111'
      @adhocSurveyNumber = @ParsedEntryLink[2][0..3]  # Will stop working if SurveyNumber is not 4 digits
      user.SurveysAttempted << @adhocSurveyNumber+'-ts='+Time.now.to_s
      user.save

      @adhocSurvey = Adhoc.where("SurveyNumber = ?", @adhocSurveyNumber).first
      if @adhocSurvey.Screener1 != nil then
        redirect_to '/users/Scrnr1'
      else
        user.SupplierLink = user.SupplierLink.drop(1)
        user.save
        redirect_to @EntryLink
      end
    else
      print "Not an ADHOC survey"
      puts
      user.SupplierLink = user.SupplierLink.drop(1)
      user.save
      redirect_to @EntryLink
    end
  end

  def Pii1Action
    session_id = session.id
    user = User.find_by session_id: session_id

    #    tracker.track(user.ip_address, 'Pii1Action')
    @EntryLink = user.SupplierLink[0]

    if params[:Pii1Resp] != nil
      user.Pii1 = params[:Pii1Resp]
      user.SupplierLink = user.SupplierLink.drop(1)
      user.save
      redirect_to @EntryLink
    else
      redirect_to '/users/Pii1'
    end
  end

  def getEmail
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    user = User.find_by session_id: session.id
    if (params[:emailid].empty? == false) then
      user.emailId = params[:emailid]
      # user.password = 'None'
      user.save
      tracker.track(user.ip_address, 'gotEmailId')
      selectP2SPullAPISurveys (session.id)
    else
      p "************** Users did not share emailid in getEmail *****************"
      # Userride should go to the next survey link instead on p2sapi links.

      if user.SupplierLink.length == 0 then
        # redirect_to '/users/nosuccess'

        if user.netid == "MMq0514UMM20bgf17Yatemoh" then
          redirect_to '/users/nosuccessPanelist'
        else
          redirect_to '/users/nosuccess'
        end

      else
        @NextEntryLink = user.SupplierLink[0]
        user.SupplierLink = user.SupplierLink.drop(1)
        user.save
        print "************>>>>User will be sent to the next Survey Entry link>>>>>>>ooooppppppp ", @NextEntryLink,  "***************************************************************"
        puts
        redirect_to @NextEntryLink
      end
    end      
  end  

  def selectP2SPullAPISurveys (session_id)
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')    
    user = User.find_by session_id: session_id

    # Queue up additional surveys from P2S. First calculate the additional values to be attached.
    @P2Sclient = Network.find_by name: "P2S"
    @SUBID = @P2Sclient.netid+user.user_id
    print "**************** P2S API @SUBID = ", @SUBID
    puts
    if user.gender == '1' then
      @p2s_gender = "m"
    else
      @p2s_gender = "f"
    end   
    
    p2s_hispanic = [0, 6729, 6730, 6898, 6900, 6901, 6902, 6903, 6904, 6905, 6906, 6907, 6908, 6909, 6910, '']
    @p2s_hispanic = p2s_hispanic[user.ethnicity.to_i].to_s
    
    p2s_employment_status = [0, 7007, 7008, 7006, 7006, 7013, 7013, 7012, 7011, 7009, 7010, 23562, '']
    @p2s_employment_status = p2s_employment_status[user.employment.to_i].to_s
    
    p2s_income_level = [0, 9089, 9089, 9089, 9071, 9072, 9088, 9073, 9087, 9074, 9086, 9090, 9075, 9091, 9076, 9092, 9077, 9093, 9078, 9094, 9079, 9080, 9081, 9082, 9085, 9084, 9084, '']
    @p2s_income_level = p2s_income_level[user.householdincome.to_i].to_s
    
    p2s_race = [0, 10094, 10095, 10101, 10097, 10098, 10104, 10109, 10110, 10111, 10096, 10102, 10106, 10107, 10108, 10103, '']
    @p2s_race = p2s_race[user.race.to_i].to_s
    
    p2s_education_level = [0, 10157, 10158, 10163, 10159, 10160, 10161, 10162, 10164, '']
    @p2s_education_level = p2s_education_level[user.eduation.to_i].to_s
    
    p2s_org_id = [0, 22942, 22934, '', '', 22936, '', 22942, '', '', 22938, '', 22957, 22957, 22957, 22957, 22938, '', '', 22939, 22940, 3650829, '', '', '', '', 22943, 22944, 22945, '', 22957, 3651719, '', 22946, 22947, 22949, 22948, 22950, '', 22952, '', 22944, 22953, '', 22954, '', '', '', '', '', 3661207, '']
    @p2s_org_id = p2s_org_id[user.pindustry.to_i].to_s
    
    p2s_jobtitle = [0, 3673669, 367670, 3673663, 3673668, 3673671, 3673675, 3673675, 3673672, 3673673, 3673674, 3673675]
    @p2s_jobtitle = p2s_jobtitle[user.jobtitle.to_i].to_s
     
    p2s_children = [0, 6971, 6972, 6971, 6972, 6973, 6974, 6975, 6976, 6977, 6978, 6979, 6980, 6981, 6982, 6983, 6984, 6985, 6986, 6987, 6988, 6989, 6990, 6991, 6992, 6993, 6994, 6995, 6996, 6997, 6998, 6999, 7000, 7001, 7002, 7003, 7004]
    
    if user.children != nil then
      if user.children[0] != '-3105' then
        @p2s_children = p2s_children[user.children[0].to_i].to_s        
        if user.children.length > 1 then            
          (1..user.children.length-1).each do |i|          
            if p2s_children[user.children[i].to_i] != '' then                  
              @p2s_children = @p2s_children+','+p2s_children[user.children[i].to_i].to_s    
            else
            end          
          end        
        else
        end
      else
        @p2s_children = '7005'
      end        
    else
      @p2s_children = ''
    end
    
    p2s_province = [0, 20509, 20508, 20511, 20515, 20517, 20519, 20516, 20520, 20512, 20514, 20513, 20510, 20518]
    @p2s_province = p2s_province[@provincePrecode.to_i].to_s        

    # p2s additional values
    if user.country=="9" then
      p2s_Api_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP+'&employment_status='+@p2s_employment_status+'&income_level='+@p2s_income_level+'&education_level='+@p2s_education_level+'&hispanic='+@p2s_hispanic+'&race='+@p2s_race+'&org_id='+@p2s_org_id+'&job_title='+@p2s_jobtitle+'&children_under_18='+@p2s_children+'&user_id='+@SUBID+'&email='+user.emailId+'&ip_address='+user.ip_address
    else
      if user.country=="6" then
        p2s_Api_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP+'&employment_status='+@p2s_employment_status+'&education_level='+@p2s_education_level+'&org_id='+@p2s_org_id+'&job_title='+@p2s_jobtitle+'&children_under_18='+@p2s_children+'&canada_regions='+@p2s_province+'&user_id='+@SUBID+'&email='+user.emailId+'&ip_address='+user.ip_address
      else
        if user.country=="5" then
          p2s_Api_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP+'&employment_status='+@p2s_employment_status+'&education_level='+@p2s_education_level+'&org_id='+@p2s_org_id+'&job_title='+@p2s_jobtitle+'&children_under_18='+@p2s_children+'&user_id='+@SUBID+'&email='+user.emailId+'&ip_address='+user.ip_address
        else
        end
      end
    end  

    print "DEBUG **** p2s_Api_AdditionalValues: ", p2s_Api_AdditionalValues
    puts


    # Ask P2S Api server for top surveys list
    require 'httparty'
    api_base_url = "https://www.your-surveys.com/suppliers_api/surveys/user"
    @failcount = 0
    user_net = Network.find_by netid: user.netid
    net_payout = user_net.payout

    puts '*************** CONNECTING TO P2S API SURVEYS'
    print "***** DEBUG **** Full API URL: ", api_base_url+'?'+p2s_Api_AdditionalValues
    puts

    # Router: 9df95db5396d180e786c707415203b95
    # API: 5b96ba34dc040bf1baf557be93f8459f

    begin
    @failcount = @failcount+1
    print "P2S API access failcount is: ", @failcount
    puts
      @p2sApiResponse = HTTParty.get(api_base_url+'?'+p2s_Api_AdditionalValues,
        :headers => {'X-YourSurveys-Api-Key' => '5b96ba34dc040bf1baf557be93f8459f'}
        )
      rescue HTTParty::Error => e
        puts 'HttParty::Error '+ e.message
      retry
    end while ((@p2sApiResponse.code != 200) && (@failcount < 10))

    @P2SApiSupplierLinks = []
    if @failcount == 10 then
      print "**** DEBUG ***** No response returned by P2S API. No SupplierLinks added. **********"
      puts
    else
      print 'http response', @p2sApiResponse
      puts    
      if @p2sApiResponse["surveys"].length == 0 then
          print "********* No surveys returned by P2S API **********"
          puts        
      else
        @NumberOfP2SSurveys = @p2sApiResponse["surveys"].length       
        print "************ Number of surveys returned by P2S API: ", @NumberOfP2SSurveys
        puts

        (0..@NumberOfP2SSurveys-1).each do |i|
          if (@p2sApiResponse["surveys"][i]["cpi"].to_f > net_payout) then
            @P2SApiSupplierLinks << @p2sApiResponse["surveys"][i]["entry_link"]
          else
          end
        end #do
        print "************ Number of surveys on P2S API which Qualify for KETSCI: ", @P2SApiSupplierLinks.length
        puts
        print "P2S API Offerwall SupplierLinks: ", @P2SApiSupplierLinks
        puts
      end
    end

    addP2SApiLinks = @P2SApiSupplierLinks + user.SupplierLink
    user.SupplierLink = addP2SApiLinks

    if user.SupplierLink.length == 0 then
      # redirect_to '/users/nosuccess'

      if user.netid == "MMq0514UMM20bgf17Yatemoh" then
        redirect_to '/users/nosuccessPanelist'
      else
        redirect_to '/users/nosuccess'
      end


    else
      @NewEntryLink = user.SupplierLink[0]
      user.SupplierLink = user.SupplierLink.drop(1)
      user.save
      print "******DEBUG******>>>>User will be sent to this first P2S API Survey Entry link>>>>>>> ", @P2SApiSupplierLinks[0],  "***************************************************************"
      puts
      redirect_to @NewEntryLink
    end
  end # selectP2SSurveys
  
  def p1action
    redirect_to '/users/p2'
  end
  
  def p2action
    redirect_to '/users/p25'
  end
  
  def p25action
    redirect_to '/users/p26'
  end
  
  def p26action
    redirect_to '/users/p3'
  end
  
  def p3action
    session_id = session.id
    user = User.find_by session_id: session_id
    # print '******************************Test SUCCESS for CID= ', user.clickid, ' NetId= ', user.netid
    # puts
    
    if user.SurveysCompleted.flatten(2).include? (user.clickid) then
      # print "************* Click Id already exists - do not postback again!"
      # puts      
    else
          
      #Postback that the Test completed     
      if user.netid == "Aiuy56420xzLL7862rtwsxcAHxsdhjkl" then

        begin
          @FyberPostBack = HTTParty.post('http://www2.balao.de/SPM4u?transaction_id='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
          rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
          end while @FyberPostBack.code != 200
    
      else
      end
    
      if user.netid == "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then
       
        begin
          @SupersonicPostBack = HTTParty.post('http://track.supersonicads.com/api/v1/processCommissionsCallback.php?advertiserId=54318&password=9b9b6ff8&dynamicParameter='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
          rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
          end while @SupersonicPostBack.code != 200
    
      else
      end  
  
      if user.netid == "CyAghLwsctLL98rfgyAHplqa1iuytIA" then

        begin
          @RadiumOnePostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?sid='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
         rescue HTTParty::Error => e
           puts 'HttParty::Error '+ e.message
          retry
        end while @RadiumOnePostBack.code != 200

      else
      end  
    
      if user.netid == "Dajsyu4679bsdALwwwLrtgarAKK98jawnbvcHiur" then
       
        begin
          @SS2PostBack = HTTParty.post('http://track.supersonicads.com/api/v1/processCommissionsCallback.php?advertiserId=54318&password=9b9b6ff8&dynamicParameter='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
            rescue HTTParty::Error => e
              puts 'HttParty::Error '+ e.message
            retry
          end while @SS2PostBack.code != 200
    
      else
      end
            
      if user.netid == "Ebkujsawin54rrALffLAki10c7654Hnms" then

        begin
          @Fyber2PostBack = HTTParty.post('http://www2.balao.de/SPNcu?transaction_id='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
          rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
          end while @Fyber2PostBack.code != 200
    
      else
      end
         
      if user.netid == "FmsuA567rw21345f54rrLLswaxzAHnms" then
        begin
          @SS3PostBack = HTTParty.post('http://track.supersonicads.com/api/v1/processCommissionsCallback.php?advertiserId=54318&password=9b9b6ff8&dynamicParameter='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
          rescue HTTParty::Error => e
            puts 'HttParty::Error '+ e.message
            retry
          end while @SS3PostBack.code != 200    
      else
      end
      
      if user.netid == "Hch1oti456bgafqaxr67lj9fmlp" then

        begin
          #@RadiumOnePostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?sid='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
          @RadiumOne2PostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?CID='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
         rescue HTTParty::Error => e
           puts 'HttParty::Error '+ e.message
          retry
        end while @RadiumOne2PostBack.code != 200
      else
      end  

      if user.netid == "IS1oti09bgaHqaTIxr67lj9fmAQ" then

        begin
          #puts "************************* TEST SENDING RADIUMONE3 POSTBACK **************************************"
          #@RadiumOne3PostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?sid='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
          @RadiumOne3PostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?CID='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
          rescue HTTParty::Error => e
           puts 'HttParty::Error '+ e.message
          retry
        end while @RadiumOne3PostBack.code != 200
      else
      end

      if user.netid == "JAL123sdegaLqaAHxr77ljedfmwqa" then

        begin
          @TapjoyPostBack = HTTParty.post('http://tapjoy.go2cloud.org/SP1mD?transaction_id='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
         rescue HTTParty::Error => e
           puts 'HttParty::Error '+ e.message
          retry
        end while @TapjoyPostBack.code != 200
      else
      end


      # No postback needed for TEST survey on Charity Network (KsAnLL23qacAHoi87ytr45bhj8) user as it is our own network.

      
      # No postback needed for TEST survey on QuickRewards (L4A..) user as it is tracked manually.


      # No postback needed for TEST survey on Panelists Network (MM..) user as it is tracked manually.


      # Keep a count of Test completes on each Network
  
      puts "*************** Track Test completes on each network"
  
      @net = Network.find_by netid: user.netid

      if @net.Flag4 == nil then
        @net.Flag4 = "1" 
      else
        @net.Flag4 = (@net.Flag4.to_i + 1).to_s
      end
  
      @net.save
  
      # Save Test completed information by user
  
      if user.netid == "Aiuy56420xzLL7862rtwsxcAHxsdhjkl" then 
        @net_name = "Fyber"
      else
      end
  
      if user.netid == "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then 
        @net_name = "SuperSonic"
      else
      end
  
      if user.netid == "CyAghLwsctLL98rfgyAHplqa1iuytIA" then 
        @net_name = "RadiumOne"
      else
      end
  
      if user.netid == "Dajsyu4679bsdALwwwLrtgarAKK98jawnbvcHiur" then 
        @net_name = "SS2"
      else
      end 
      
      if user.netid == "Ebkujsawin54rrALffLAki10c7654Hnms" then 
        @net_name = "Fyber2"
      else
      end
      
      if user.netid == "FmsuA567rw21345f54rrLLswaxzAHnms" then 
        @net_name = "SS3"
      else
      end
      
      if user.netid == "Gd7a7dAkkL333frcsLA21aaH" then 
        @net_name = "MemoLink"
      else
      end
      
      if user.netid == "Hch1oti456bgafqaxr67lj9fmlp" then 
        @net_name = "RadiumOne2"
      else
      end

      if user.netid == "IS1oti09bgaHqaTIxr67lj9fmAQ" then 
        @net_name = "RadiumOne3"
      else
      end

      if user.netid == "JAL123sdegaLqaAHxr77ljedfmwqa" then 
        @net_name = "TapJoy"
      else
      end

      if user.netid == "KsAnLL23qacAHoi87ytr45bhj8" then 
        @net_name = "Charity"
      else
      end

      if user.netid == "L4AnLLfc4rAHpl12as3ggg986" then 
        @net_name = "QuickRewards"
      else
      end
    
      user.SurveysAttempted << 'TESTSURVEY'
      user.SurveysCompleted[Time.now] = [user.user_id, 'TESTSURVEY', 'KETSCI', '$0', user.clickid, @net_name]

      #user.SurveysCompleted[user.user_id] = [Time.now, 'TESTSURVEY', user.clickid, @net_name]
      user.save    
    end # duplicate is false
    
    

    if user.netid == "Gd7a7dAkkL333frcsLA21aaH" then
      redirect_to '/users/successfulMML'
    else
      if user.netid == "KsAnLL23qacAHoi87ytr45bhj8" then
        redirect_to '/users/successfulCharity'
      else
        if user.netid == "L4AnLLfc4rAHpl12as3ggg986" then
          redirect_to 'http://apps.intapi.com/rd.int?o=ke&si=KE1234KE&r=1&s='+user.clickid
        else
          if user.netid == "MMq0514UMM20bgf17Yatemoh" then
            redirect_to '/users/successfulPanelist'
          else
            redirect_to '/users/successful'
          end
        end
      end
    end  
  end # p3action
end