class UsersController < ApplicationController

  require 'httparty'
  require 'mixpanel-ruby'
  require 'hmac-md5'

  def new
    #    @user = User.new
  end

  def show
  end
  
  def create
  end

  def eval_age

    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    if params[:age].empty? == false
      @age = params[:age]
    else
      redirect_to '/users/new'
      return
    end

     # Check for COPA eligibility

    if @age.to_i<13 then
      p '********************* Entered age is < 13'
      redirect_to '/users/nosuccess'
    else  
      # Enter the user with the following credentials in our system or find user's record  
      ip_address = request.remote_ip
      session_id = session.id
      netid = params[:netid]
      clickid = params[:clickid]
      
      
      # Keep track of clicks on each network as Flag2
      
      @SSnet = Network.find_by netid: netid
      if @SSnet.Flag2 == nil then
        @SSnet.Flag2 = "1" 
        @SSnet.save
      else
        @SSnet.Flag2 = (@SSnet.Flag2.to_i + 1).to_s
        @SSnet.save
      end
        
     
      tracker.track(ip_address, 'Age')
      
      # Change this to include validating a cookie first(more unique compared to IP address id) before verifying by IP address      
      # if ((User.where(ip_address: ip_address).exists?) && (User.where(session_id: session.id).exists?)) then
 
      if (User.where("ip_address = ? AND session_id = ?", ip_address, session_id).first!=nil)
        first_time_user=false
        # p '********* EVAL_AGE: USER EXISTS'
      else
        first_time_user=true
        # p 'EVAL_AGE: USER DOES NOT EXIST'
      end

      if (first_time_user) then
        # Create a new-user record
        p '****************** EVAL_AGE: Creating new record for FIRST TIME USER'
        #  @user = User.new(user_params)
        @user = User.new
        @user.age = @age
        @user.netid = netid
        @user.clickid = clickid
#       @user.payout = should be extracted from advertiser id in call
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
        p @user
        redirect_to '/users/tos'
      else
      end
    
    
    
      # This DB call should be optimized by using the id of record already found before
      
      if (first_time_user==false) then
        user = User.where("ip_address = ? AND session_id = ?", ip_address, session_id).first
        p user

        # Why do I have to stop at first? Optimizes. But there should be not more than 1 entry.

        if user.black_listed==true then
          p '******************* EVAL_AGE: REPEAT USER is Black listed'
          userride (session_id)
        else
          p '******************* EVAL_AGE: Modifying existing user record of a REPEAT USER'

          user.age = @age
          user.netid = netid
          user.clickid = clickid
          # These get a blank entry on the list due to save action?
          user.QualifiedSurveys = []
          user.SurveysWithMatchingQuota = []
          user.SupplierLink = []
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

    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
      
    user=User.find_by session_id: session.id
    user.tos=true

    tracker.track(user.ip_address, 'TOS')

    # Update number of attempts in last 24 hrs record of the user
    if ( user.number_of_attempts_in_last_24hrs==nil ) then
      user.number_of_attempts_in_last_24hrs=user.attempts_time_stamps_array.count { |x| x > (Time.now-1.day) }
    else
    end
    
    user.save
    
    # Address good and bad repeat access behaviour after they have resigned TOS (PP)
    if ( user.attempts_time_stamps_array.length==1 ) then
      p 'TOS: FIRST TIME USER'
      redirect_to '/users/qq2'
    else
      p 'TOS: A REPEAT USER'
      # set 24 hr survey attempts in separate sessions from same device/IP address here
      if (user.number_of_attempts_in_last_24hrs < 50) then
        # skip gender and other demo questions due to responses in last 24 hrs
#        redirect_to '/users/qq9'
        redirect_to '/users/qq2'
      else
        # user has made too many attempts to take surveys
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
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
  
    
    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'Trap Q1')
    
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
    
#   tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    
    user=User.find_by session_id: session.id
    
#     tracker.track(user.ip_address, 'Country')
    
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
            if user.country=="0" then
             redirect_to '/users/nosuccess'
            else
             redirect_to '/users/qq3'
            end
          end
        end
      end
    end
  
  end
  
  def zip_US

    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    

    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'Zip')
    
    if params[:zip].empty? == false
      user.ZIP=params[:zip]
      user.save
      redirect_to '/users/qq7_US'
    else
      redirect_to '/users/qq4_US'
    end

  end
  
  def zip_CA

    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    

    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'CA_Zip')
    
    
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
    
    tracker.track(user.ip_address, 'IN_PIN')
 
    
    if params[:zip].empty? == false
      user.ZIP=params[:zip]
      user.save
      redirect_to '/users/qq7_IN'
    else
      redirect_to '/users/qq4_IN'
    end  
    
  end
  
  def zip_AU
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    
    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'AU_Zip')
    

    if params[:zip].empty? == false
      user.ZIP=params[:zip]
      user.save
      redirect_to '/users/qq7_AU'
    else
      redirect_to '/users/qq4_AU'
    end
    
  end
  
  def ethnicity_US
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'ethnicity_US')
    
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
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'hhi_US')
    
    if params[:hhi] != nil
      user.householdincome=params[:hhi]
      user.save
      redirect_to '/users/qq5_US'
    else
      redirect_to '/users/qq8_US'
    end
    
  end

  def householdincome_CA
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
     tracker.track(user.ip_address, 'hhi_CA')
    
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
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
     tracker.track(user.ip_address, 'hhi_AU')
    
    if params[:hhi] != nil
      user.householdincome=params[:hhi]
      user.save      
      redirect_to '/users/qq10'
    else
      redirect_to '/users/qq8_AU'
    end
    
  end
    
  def householdcomp  

#    user=User.find_by session_id: session.id
###    user.householdcomp=params[:householdcomp][:range]
#    user.householdcomp=params[:householdcomp]
#    user.save
#    ranksurveysforuser(session.id)
  end  
  
  def employment
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'employment')    
    
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
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'pindustry')
    
    if params[:pindustry] != nil
      user.pindustry=params[:pindustry]
      user.save
      redirect_to '/users/qq13'
    else
      redirect_to '/users/qq11'
    end
    
  end
  
  def jobtitleaction  
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'jobtitle')
    
    if params[:jtitle] != nil
      user.jobtitle=params[:jtitle]
      user.save
      redirect_to '/users/qq14'
    else
      redirect_to '/users/qq13'
    end
    
  end 
  
  def childrenaction  
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'children')
    
    if params[:children] != nil
      user.children=params[:children]
      user.save
      print "______________________________________>>> user.children.flatten: ", user.children.flatten
      puts
      print "______________________________________>>> user.children[0]: ", user.children[0]
      puts
      redirect_to '/users/qq12'
    else
      redirect_to '/users/qq14'
    end
    
  end 
  
  def pleasewait
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'pleasewait')    
    
    ranksurveysforuser(session.id)
    
  end
  
  def ranksurveysforuser (session_id)

    user=User.find_by session_id: session_id
    
    if user.gender == '1' then
      @GenderPreCode = [ "1" ]
    else
      @GenderPreCode = [ "2" ]
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

    # Lets find surveys that user is qualified for.
      
    # If this is a TEST e.g. with a network provider then route user to run the standard test survey.

    @netid = user.netid
    @poorconversion = false
      
    if Network.where(netid: @netid).exists? then
      net = Network.find_by netid: @netid
        
      if net.payout == nil then
        @currentpayout = 1.49 
      else
        @currentpayout = net.payout  
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
    
    # Set RFG priority
    
    @RFGIsFront = false
    @RFGIsBack = false
    @RFGIsOff = false
    
    
    if net.stackOrder != nil then
      if (net.stackOrder == "RFGISFRONT") then
        @RFGIsFront = true
        puts "**************** RFG IS at the aHead of FED"
            
      else
        if (net.Flag5 == "RFGISBACK") then
          @RFGIsBack = true
          puts "**************** RFG IS at the Back of FED"
              
        else
          if (net.Flag5 == "RFGISOFF") then
            @RFGIsOff = true
          else
          end    
        end
      end
    else
      @RFGIsOff = true
    end
    

    # Set the priority for P2S stack
        
    @foundtopsurveyswithquota = false   # false means not finished finding top FED surveys (set it to true if testing p2s)
    # puts "**************** P2S is NOT at the Head"
        
    if net.FED_US != nil then
      if (net.FED_US == 0) && (user.country == "9") then
        @foundtopsurveyswithquota = true # true takes users to P2S directly, if set as HEAD
        # puts "**************** P2S IS at the Head"

      else
        @fed_US = net.FED_US
      end
    else
      @fed_US = 1
    end
      
    if net.FED_CA != nil then
      if (net.FED_CA == 0) && (user.country == "6") then
        @foundtopsurveyswithquota = true # true takes users to P2S directly, if set as HEAD
        # puts "**************** P2S IS at the Head"

      else
        @fed_CA = net.FED_CA
      end        
    else
      @fed_CA = 1
    end
      
    if net.FED_AU != nil then
      if (net.FED_AU == 0) && (user.country == "5") then
        @foundtopsurveyswithquota = true # true takes users to P2S directly, if set as HEAD
        # puts "**************** P2S IS at the Head"

      else
        @p2s_AU = net.FED_AU
      end        
    else
      @p2s_AU = 1
    end
    
    if @poorconversion then
      @topofstack = 1
    else
      # make top of Custom surveys as starting spot for picking qualified surveys
      @topofstack = 96
    end

    print "**************************** PoorConversion is turned: ", @poorconversion, ' Topofstack is: ', @topofstack
    puts

    puts "**************************** STARTING SEARCH FOR SURVEYS USER QUALIFIES FOR"
    
    # change countrylanguageid setting to match user countryID only
    @usercountry = (user.country).to_i


    Survey.where("CountryLanguageID = ? AND SurveyGrossRank >= ?", @usercountry, @topofstack).order( "SurveyGrossRank" ).each do |survey|

      if @foundtopsurveyswithquota == false then  #3 false means not finished finding top surveys
        

        if ( ((survey.CountryLanguageID == 5) || (survey.CountryLanguageID == 6)) &&          
          ( survey.SurveyStillLive ) && 
          (( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([ user.age ] & survey.QualificationAgePreCodes.flatten) == [ user.age ] )) && 
          (( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || ((@GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )) && 
          (( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])) &&
          (( survey.QualificationRacePreCodes.empty? ) || ( survey.QualificationRacePreCodes.flatten == [ "ALL" ] ) || (([ user.race ] & survey.QualificationRacePreCodes.flatten) == [ user.race ])) &&
          (( survey.QualificationEthnicityPreCodes.empty? ) || ( survey.QualificationEthnicityPreCodes.flatten == [ "ALL" ] ) || (([ user.ethnicity ] & survey.QualificationEthnicityPreCodes.flatten) == [ user.ethnicity ])) &&
          (( survey.QualificationEducationPreCodes.empty? ) || ( survey.QualificationEducationPreCodes.flatten == [ "ALL" ] ) || (([ user.eduation ] & survey.QualificationEducationPreCodes.flatten) == [ user.eduation ])) &&
          (( survey.QualificationHHIPreCodes.empty? ) || ( survey.QualificationHHIPreCodes.flatten == [ "ALL" ] ) || (([ user.householdincome ] & survey.QualificationHHIPreCodes.flatten) == [ user.householdincome ])) &&
          (( survey.QualificationEmploymentPreCodes.empty? ) || ( survey.QualificationEmploymentPreCodes.flatten == [ "ALL" ] ) || (([ user.employment ] & survey.QualificationEmploymentPreCodes.flatten) == [ user.employment ])) &&
          (( survey.QualificationPIndustryPreCodes.empty? ) || ( survey.QualificationPIndustryPreCodes.flatten == [ "ALL" ] ) || (([ user.pindustry ] & survey.QualificationPIndustryPreCodes.flatten) == [ user.pindustry ])) &&     
          (( survey.QualificationJobTitlePreCodes.empty? ) || ( survey.QualificationJobTitlePreCodes.flatten == [ "ALL" ] ) || (([ user.jobtitle ] & survey.QualificationJobTitlePreCodes.flatten) == [ user.jobtitle ])) &&
          (( survey.QualificationChildrenPreCodes.empty? ) || ( survey.QualificationChildrenPreCodes.flatten == [ "ALL" ] ) || (( user.children & survey.QualificationChildrenPreCodes.flatten).empty? == false)) &&
          ((survey.CPI == nil) || (survey.CPI >= @currentpayout)) ) ||
          
          ( (survey.CountryLanguageID == 9) &&          
          ( survey.SurveyStillLive ) && 
          (( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([ user.age ] & survey.QualificationAgePreCodes.flatten) == [ user.age ] )) && 
          (( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || ((@GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )) && 
          (( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])) &&
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
          (( survey.QualificationDivisionPreCodes.empty? ) || ( survey.QualificationDivisionPreCodes.flatten == [ "ALL" ] ) || (([ @divisionPrecode ] & survey.QualificationDivisionPreCodes.flatten) == [ @divisionPrecode ])) &&         
          ((survey.CPI == nil) || (survey.CPI >= @currentpayout)) )
          
          then
          
        
          #Prints for testing code

          @_gender = ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (( @GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )
          @_age = ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([user.age] & survey.QualificationAgePreCodes.flatten) == [user.age])
          @_age_value = [user.age] & survey.QualificationAgePreCodes.flatten
          @_ZIP = ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
          @_race = (( survey.QualificationRacePreCodes.empty? ) || ( survey.QualificationRacePreCodes.flatten == [ "ALL" ] ) || (([ user.race ] & survey.QualificationRacePreCodes.flatten) == [ user.race ]))
          @_ethnicity= (( survey.QualificationEthnicityPreCodes.empty? ) || ( survey.QualificationEthnicityPreCodes.flatten == [ "ALL" ] ) || (([ user.ethnicity ] & survey.QualificationEthnicityPreCodes.flatten) == [ user.ethnicity ]))
          @_education= (( survey.QualificationEducationPreCodes.empty? ) || ( survey.QualificationEducationPreCodes.flatten == [ "ALL" ] ) || (([ user.eduation ] & survey.QualificationEducationPreCodes.flatten) == [ user.eduation ]))
          @_HHI= (( survey.QualificationHHIPreCodes.empty? ) || ( survey.QualificationHHIPreCodes.flatten == [ "ALL" ] ) || (([ user.householdincome ] & survey.QualificationHHIPreCodes.flatten) == [ user.householdincome ]))
          @_employment = (( survey.QualificationEmploymentPreCodes.empty? ) || ( survey.QualificationEmploymentPreCodes.flatten == [ "ALL" ] ) || (([ user.employment ] & survey.QualificationEmploymentPreCodes.flatten) == [ user.employment ]))
          @_pindustry = (( survey.QualificationPIndustryPreCodes.empty? ) || ( survey.QualificationPIndustryPreCodes.flatten == [ "ALL" ] ) || (([ user.pindustry ] & survey.QualificationPIndustryPreCodes.flatten) == [ user.pindustry ]))
          @_jobtitle = (( survey.QualificationJobTitlePreCodes.empty? ) || ( survey.QualificationJobTitlePreCodes.flatten == [ "ALL" ] ) || (([ user.jobtitle ] & survey.QualificationJobTitlePreCodes.flatten) == [ user.jobtitle ]))          
          @_children = (( survey.QualificationChildrenPreCodes.empty? ) || ( survey.QualificationChildrenPreCodes.flatten == [ "ALL" ] ) || (( user.children  & survey.QualificationChildrenPreCodes.flatten).empty? == false)) 
          @_children_logic = user.children & survey.QualificationChildrenPreCodes.flatten       
          @_CPI_check = ((survey.CPI == nil) || (survey.CPI >= @currentpayout))

        
          print '************ User QUALIFIED for survey number = ', survey.SurveyNumber, ' RANK= ', survey.SurveyGrossRank, ' User enetered Gender: ', @GenderPreCode, ' Gender from Survey= ', survey.QualificationGenderPreCodes, ' USER ENTERED AGE= ', user.age, ' AGE PreCodes from Survey= ', survey.QualificationAgePreCodes, ' User Entered ZIP: ', user.ZIP, ' ZIP PreCodes from Survey: ..... ', ' User Entered Race: ', user.race, ' Race PreCode from survey: ', survey.QualificationRacePreCodes, ' User Entered ethnicity: ', user.ethnicity, ' Ethnicity PreCode from survey: ', survey.QualificationEthnicityPreCodes, ' User Entered education: ', user.eduation, ' Education PreCode from survey: ', survey.QualificationEducationPreCodes, ' User Entered HHI: ', user.householdincome, ' HHI PreCode from survey: ', survey.QualificationHHIPreCodes, ' User Entered Employment: ', user.employment, ' Std_Employment PreCode from survey: ', survey.QualificationEmploymentPreCodes, ' User Entered PIndustry: ', user.pindustry, ' PIndustry PreCode from survey: ', survey.QualificationPIndustryPreCodes, ' User Entered JobTitle: ', user.jobtitle, ' JobTitle PreCode from survey: ', survey.QualificationJobTitlePreCodes, ' User Entered Children: ', user.children, ' Children PreCodes from survey: ', survey.QualificationChildrenPreCodes, ' Network Payout: ', @currentpayout, ' CPI from survey: ', survey.CPI, ' SurveyStillAlive: ', survey.SurveyStillLive
         
        puts
        
        print '************* Gender match: ', @_gender, ' Age match: ', @_age, ' Age_logic value: ', @_age_value, ' ZIP match: ', @_ZIP, ' Race match: ', @_race, ' Ethnicity match: ', @_ethnicity, ' Education match: ', @_education, ' HHI match: ', @_HHI, ' Employment match: ', @_employment, ' PIndustry match: ', @_pindustry, ' JobTitle match: ', @_jobtitle, ' Children match: ', @_children, ' Children_logic value: ', @_children_logic, ' CPI check: ', @_CPI_check
        puts
        

        if (survey.CountryLanguageID == 9) then
          
          @_DMA = (( survey.QualificationDMAPreCodes.empty? ) || ( survey.QualificationDMAPreCodes.flatten == [ "ALL" ] ) || (([ @DMARegionCode ] & survey.QualificationDMAPreCodes.flatten) == [ @DMARegionCode ]))
          @_State = (( survey.QualificationStatePreCodes.empty? ) || ( survey.QualificationStatePreCodes.flatten == [ "ALL" ] ) || (([ @statePrecode ] & survey.QualificationStatePreCodes.flatten) == [ @statePrecode ]))
          @_region = (( survey.QualificationRegionPreCodes.empty? ) || ( survey.QualificationRegionPreCodes.flatten == [ "ALL" ] ) || (([ @regionPrecode ] & survey.QualificationRegionPreCodes.flatten) == [ @regionPrecode ]))
          @_Division = (( survey.QualificationDivisionPreCodes.empty? ) || ( survey.QualificationDivisionPreCodes.flatten == [ "ALL" ] ) || (([ @divisionPrecode ] & survey.QualificationDivisionPreCodes.flatten) == [ @divisionPrecode ]))        
          
          print '************** DMA match: ', @_DMA, ' State match: ', @_State, ' Region match: ', @_region, ' Division match: ', @_Division
          puts
        else
        end

        user.QualifiedSurveys << survey.SurveyNumber
        
        print '********** This USER_ID: ', user.user_id, ' has QUALIFIED for the following survey : ', survey.SurveyNumber
        puts
        
        print '********** In total This USER_ID: ', user.user_id, ' has QUALIFIED for the following surveys: ', user.QualifiedSurveys
        puts
              

          # Lets save the surveys user qualifies for in this user's record of database in rank order
          user.save
          
# redundant?

          # Look through the survey this user is qualified for, to check if there is quota available. Quota numbers can be read as Maximum or upper limit allowed for a qualification e.g. ages 20-24 quota of 30 and ages 25-30 quota of 50 is the upper limit on both of the groups. The code should first find if the number of respondents in the quota teh respondent falls in has need for more respondents. When a quota is split into parts then respondent must fall into at least one of them.
      
      
          puts "********************* STARTING To SEARCH if QUOTA is available for this user in the surveys user is Qualified. Stop after specified number of top ranked surveys with quota are found"
      
      
 #         (0..user.QualifiedSurveys.length-1).each do |j| #1
 # delete the j loop and move the section below into the before else clause of qualified surveys found        
          
#            @surveynumber = user.QualifiedSurveys[j]
# delete above and use the survey number in Qualifications j-loop
            
            @surveynumber = survey.SurveyNumber
        
        
#            Survey.where( "SurveyNumber = ?", @surveynumber).each do |survey| #2
    # delete the line above because we will be in the qualifications do loop for this survey number


            @NumberOfQuotas = survey.SurveyQuotas.length-1
            print '************ The Number of Quota IDs in this survey are more than 1: ', @NumberOfQuotas+1
            puts
            print '************ Lets examine if there are any Total+Quotas (k) open for this user'
            puts

            # each survey specifies k quotas each
        
            # first entry (k=0) is always for Total quota. Check if total quota exists i.e. respondents/completes are needed.
            totalquotaexists = false
        
            if (survey.SurveyQuotas[0]["SurveyQuotaType"] == "Total" ) then  #3
           
              puts "**************** Found Total quota values"       
              if survey.SurveyQuotas[0]["NumberOfRespondents"] > 0 then #4
                print 'Total quota numberofrespondents is: ', survey.SurveyQuotas[0]["NumberOfRespondents"]
                puts
                totalquotaexists = true
              else #4
                # Total NumberOfRespondent needed = 0. No completes required
                print '************* No completes required - no quota available for this syurvey: ', survey.SurveyNumber
                puts
              end #4
            else #3
              # Lets assume that quota is open for all users so add this survey number to user's ride
              print '************* No Total quota ID found. Assuming that quota is open for ALL users. Might want to change this to refuse this survey based on experience. This should typically NOT happen.'
              puts
              user.SurveysWithMatchingQuota << @surveynumber
          
              if (user.country == '9') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_US) then
            
                @foundtopsurveyswithquota = true
          
              else
            
                if (user.country == '6') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_CA) then
              
                  @foundtopsurveyswithquota = true
            
                else
            
                  if (user.country == '5') && (user.SurveysWithMatchingQuota.uniq.length >= @p2s_AU) then
                
                    @foundtopsurveyswithquota = true
              
                  else
              
                    #do nothing
              
                  end
            
                end
          
              end
          
            end #3
          

            # Review quota IDs if there are more entries than Total quota (at k=0)
        
            if (totalquotaexists) && (@NumberOfQuotas > 0) then #5

              # Assume all quotas are closed unless proven false
              agequotaexists = false
              genderquotaexists = false
              @ZIPquotaexists = false
              ethnicityquotaexists = false
              racequotaexists = false
              educationquotaexists = false
              hhiquotaexists = false
          
          
              # These will help ensure that if a questionID exists in a survey - we make sure that the user meets that question ID's quota
              @agequotavalidationwasdone = false
              @genderquotavalidationwasdone = false
              @zipquotavalidationwasdone = false
              @ethnicityquotavalidationwasdone = false
              @racequotavalidationwasdone = false
              @educationquotavalidationwasdone = false
              @hhiquotavalidationwasdone = false
          
              # Create a new list for each survey
              @listofunmatchednestedquestionIDs = Array.new
              @NestedQuestionIDstringArray = Array.new
          
              # Go through each quota (k)
          
              (1..@NumberOfQuotas).each do |k| #6
                puts '***************** Starting at the next value of k i.e. next QuotaID: ', survey.SurveyQuotas[k]["SurveyQuotaID"]
                @NumberOfRespondents = survey.SurveyQuotas[k]["NumberOfRespondents"]
                print 'Number of respondents =, in this quota ID index k=: ', @NumberOfRespondents, ' ', k
                puts
                print '***** Questions in this quota: ', survey.SurveyQuotas[k]["Questions"]
                puts            

            
              if survey.SurveyQuotas[k]["NumberOfRespondents"] > 0 then #7
            
                print '****************** Needs respondents at k=', k
                puts
            
                @NumberOfQuestions = survey.SurveyQuotas[k]["Questions"].length
            
                print '*********************** Number of questions = ', @NumberOfQuestions
                puts
            
                if @NumberOfQuestions == 1 then #8 unnested quota
 
    #              (0..survey.SurveyQuotas[k]["Questions"].length-1).each do |l| #10
                
                    l = 0
                    puts '**************** Number of questions is 1. Setting l=0'
                    print '*********** Question ID= for the question is: ', survey.SurveyQuotas[k]["Questions"][l]["QuestionID"]
                    puts
              
                  # check if a quota exists for this user by matching precodes for the questions (at l=0) in a quota (k)
            
              
                  case survey.SurveyQuotas[k]["Questions"][l]["QuestionID"] #9
                
                    when 42
                      print 'Age: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      @agequotavalidationwasdone = true
                  
                      if ([ user.age ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.age ] ) then
                        agequotaexists=true                     
                        puts '*********** Age question matches'
                      else
                        agequotaexists = false || agequotaexists
                        print '********************************************************************* Age question does not match: ', agequotaexists
                        puts
                      end
                  
                    when 43
                      print 'Gender: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      @genderquotavalidationwasdone = true
                  
                      if ( @GenderPreCode & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == @GenderPreCode ) then
                        genderquotaexists=true
                        puts '************ Gender question matches'
                      else
                        genderquotaexists=false || genderquotaexists
                        print '******************************************************************* Gender question does not match: ', genderquotaexists
                        puts
                      end
                  
                    when 45
                  #    print 'ZIPS: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                  #    puts
                      @zipquotavalidationwasdone=true
 
                    # Except for Canada, check for zip in other countries

                      if ((user.country == 6) || ( [ user.ZIP ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ZIP ] )) then
                        @ZIPquotaexists=true
                       puts '********** ZIP question matches'
                      else
                        @ZIPquotaexists=false || @ZIPquotaexists
                        puts '********** ZIP question does not match'
                      end
                  
                    when 47
                      print 'Ethnicity (47, Hispanic): ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      @ethnicityquotavalidationwasdone = true
                  
                      if ([ user.ethnicity ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ethnicity ] ) then
                        ethnicityquotaexists = true
                        puts '*********** Ethnicity question matches'
                      else
                        ethnicityquotaexists = false || ethnicityquotaexists
                        print '******************************************************************* Ethnicity question does not match: ', ethnicityquotaexists
                        puts
                      end
                  
                  
                    when 113
                      print 'Race (113, Ethnicity): ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      @racequotavalidationwasdone=true
                  
                      if ([ user.race ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.race ] ) then
                        racequotaexists = true
                        puts '*********** Race question matches'
                      else
                        racequotaexists = false || racequotaexists
                        puts '*********** Race question does not match'
                      end
                  
                  
                    when 633
                      print 'Education: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      @educationquotavalidationwasdone=true
                  
                      if ([ user.eduation ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.eduation ] ) then
                        educationquotaexists = true
                        puts '*********** Education question matches'
                      else
                        educationquotaexists = false || educationquotaexists
                        puts '*********** Education question does not match'
                      end
                  
                    when 14785
                      print 'Std_HHI_US: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      @hhiquotavalidationwasdone=true
                  
                      if ([ user.householdincome ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.householdincome ] ) then
                        hhiquotaexists = true
                        puts '*********** Std_HHI_US question matches'
                      else
                        hhiquotaexists = false || hhiquotaexists
                        puts '*********** Std_HHI_US question does not match'
                      end
                  
                    when 14887
                      print 'Std_HHI_INT: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      @hhiquotavalidationwasdone=true
                  
                      if ([ user.householdincome ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.householdincome ] ) then
                        hhiquotaexists = true
                        puts '*********** Std_HHI_INT question matches'
                      else
                        hhiquotaexists = false || hhiquotaexists
                        puts '*********** Std_HHI_INT question does not match'
                      end
                  
                    end #9 End case
                
    #              end  #10 end of reviewing the question (where l = 0) for fit in a quota (k) - removed by setting l=o
              
                               
                else #8 nested quota i.e. no. of questions (l) > 1
              
              
                  @nestedagequotaexists = true
                  @nestedgenderquotaexists = true
                  @nestedzipquotaexists = true
                  @nestedethnicityquotaexists = true
                  @nestedracequotaexists = true
                  @nestededucationquotaexists = true
                  @nestedhhiquotaexists = true
              
              
                  # we will need to name this nested condition. create a nested question ID
                  @NestedQuestionID = Array.new
              
              
                  (0..survey.SurveyQuotas[k]["Questions"].length-1).each do |l| #11
                    print '******** Looping through each question (l=) of a nested quota (k): ', l
                    puts
                    print '*********** Question ID = for this l (above) position in this nested quota is: ', survey.SurveyQuotas[k]["Questions"][l]["QuestionID"]
                    puts

                  # check if a quota exists for this user by matching precodes for all questions (l) in a quota (k)
              
                  case survey.SurveyQuotas[k]["Questions"][l]["QuestionID"] #12
                
                    when 42
                      print 'Age: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                       # @agequotavalidationwasdone = true
                      @NestedQuestionID << 42
                  
                      if ([ user.age ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.age ] ) then
                        @nestedagequotaexists=true                     
                        puts '*********** Nested Age question matches'
                      else
                        @nestedagequotaexists=false
                        puts '*********** Nested Age question does not match'
                      end
                  
                    when 43
                      print 'Gender: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      # @genderquotavalidationwasdone=true
                      @NestedQuestionID << 43
                  
                      if ( @GenderPreCode & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == @GenderPreCode ) then
                        @nestedgenderquotaexists=true
                        puts '************ nested Gender question matches'
                      else
                        @nestedgenderquotaexists=false
                        puts '************* nested Gender question does not match'
                      end
                  
                    when 45
                   #   print 'ZIPS: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                  #   puts
                      # @zipquotavalidationwasdone=true
                      @NestedQuestionID << 45
 
                    # Except for Canada, check for zip in other countries

                      if ((user.country == 6) || ( [ user.ZIP ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ZIP ] )) then
                        @nestedzipquotaexists=true
                       puts '********** nested ZIP question matches'
                      else
                        @nestedzipquotaexists=false
                        puts '********** nested ZIP question does not match'
                      end
                  
                    when 47
                      print 'Ethnicity (47, Hispanic): ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      # @ethnicityquotavalidationwasdone=true
                      @NestedQuestionID << 47
                  
                      if ([ user.ethnicity ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ethnicity ] ) then
                        @nestedethnicityquotaexists = true
                        puts '*********** nested Ethnicity question matches'
                      else
                        @nestedethnicityquotaexists = false
                        puts '*********** nested Ethnicity question does not match'
                      end
                  
                  
                    when 113
                      print 'Race (113, Ethnicity): ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      # @racequotavalidationwasdone=true
                      @NestedQuestionID << 113
                  
                      if ([ user.race ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.race ] ) then
                        @nestedracequotaexists = true
                        puts '*********** nested Race question matches'
                      else
                        @nestedracequotaexists = false
                        puts '*********** Race  question does not match'
                      end
                  
                  
                    when 633
                      print 'Education: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      # @educationquotavalidationwasdone=true
                      @NestedQuestionID << 633
                  
                      if ([ user.eduation ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.eduation ] ) then
                        @nestededucationquotaexists = true
                        puts '*********** nested Education question matches'
                      else
                        @nestededucationquotaexists = false
                        puts '*********** nested Education question does not match'
                      end
                  
                    when 14785
                      print 'Std_HHI_US: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      # @hhiquotavalidationwasdone=true
                      @NestedQuestionID << 14785
                  
                      if ([ user.householdincome ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.householdincome ] ) then
                        @nestedhhiquotaexists = true
                        puts '*********** nested Std_HHI_US question matches'
                      else
                        @nestedhhiquotaexists = false
                        puts '*********** nested Std_HHI_US question does not match'
                      end
                  
                    when 14887
                      print 'Std_HHI_INT: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      puts
                      # @hhiquotavalidationwasdone=true
                      @NestedQuestionID << 14887
                  
                      if ([ user.householdincome ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.householdincome ] ) then
                        @nestedhhiquotaexists = true
                        puts '*********** nested Std_HHI_INT question matches'
                      else
                        @nestedhhiquotaexists = false
                        puts '*********** nested Std_HHI_INT question does not match'
                      end
                  
                    end #12 End case

                  end  #11 Next l until End of do l for l > 0 - end of reviewing all questions for fit in quota (k)              
              
                    # Quota k exists if qualifications for user profile match with all nested questions (l) in quota (k)
                    if ((@nestedagequotaexists == false) || (@nestedgenderquotaexists == false) || (@nestedzipquotaexists == false) || (@nestedethnicityquotaexists == false) || (@nestedracequotaexists == false) || (@nestededucationquotaexists == false) || (@nestedhhiquotaexists == false)) then
                      puts '**************** Is true even if any one @nestedquotaexists is false i.e. if user does not meet at least one of the nested criteria.  => This Quota ID is closed for this user.'
                      nestedquota = false
                    else
                      puts '*************** Is false only if ALL @nestedquotaexists are simultaneously = true or one or more questions do not match. Therefore, these nested questions match the user. This quota ID is open for this user.'
                      nestedquota = true
                  
                    end # End if   
                  
                    # Keep a list of all nested quota names
                    @nestedquotaname = @NestedQuestionID.uniq.sort.join
                      print 'New nested questionID string formed: ', @nestedquotaname
                      puts
                      print 'Items in the list of nested quotas array BEFORE: ', @NestedQuestionIDstringArray
                      puts
                      print 'Items in the list of unmatched nested quotas list BEFORE: ', @listofunmatchednestedquestionIDs
                      puts
                  
                      # if the nested condition was found true in a previous instance then do not add to unmatched list else do
                      if (nestedquota == false) then 
                        if (@NestedQuestionIDstringArray.include?(@nestedquotaname)) then
                          if (@listofunmatchednestedquestionIDs.include?(@nestedquotaname) == false) then
                            puts '************it must have been true before => so do nothing'
                        
                          else
                            puts '************* it is already on the unmatched and all nested quotas list => so do nothing'
                          end
                        else
                          puts '*************** this nested question has not ocurred before => so it should be added to the unmatched list and the list of nestedquota names.'
                          @listofunmatchednestedquestionIDs << @nestedquotaname
                          @NestedQuestionIDstringArray << @nestedquotaname
                        end
                      else
                        puts '************** nestedquota is true. add to list of nestedquota names. if it was previously not then remove it from unmatched list.'
                        @NestedQuestionIDstringArray << @nestedquotaname
                        if @listofunmatchednestedquestionIDs.include?(@nestedquotaname) then
                          @listofunmatchednestedquestionIDs.delete(@nestedquotaname)
                        else
                          puts '*********** do nothing because the quota is satisfied'
                        end
                      end  
              
                      print 'Items in the list of nested quotas array AFTER: ', @NestedQuestionIDstringArray
                      puts
                      print 'Items in the list of unmatched nested quotas list AFTER: ', @listofunmatchednestedquestionIDs
                      puts
              
              
              
                  end # 8 when all nested quotas (l) across a k subquota have been reviewed when NOR > 0
              
                else #7 NumbeOfRespondents for this Quota ID is <= 0
                  # No need to review questions for match
                end # 7                   
              end #6 Next k until End do k - checked all quota IDs from k = 1 and above
          


              # for all unnested quotas across all k sub-quotas
          
              # These flags help figure out which question IDs were in the quota and if user qualifies for the question whose pre-codes are typically split into separate quotas
              agequotaok = true
              genderquotaok = true
              zipquotaok = true
              ethnicityquotaok = true
              racequotaok = true
              educationquotaok = true
              hhiquotaok = true
          
            
              if @agequotavalidationwasdone then
                if agequotaexists then
                  agequotaok = true
                else
                  agequotaok = false
                end
              else
              end
          
              if @genderquotavalidationwasdone then
                if genderquotaexists then
                  genderquotaok = true
                else
                  genderquotaok = false
                end
              else
              end
          
              if @zipquotavalidationwasdone then
                if @ZIPquotaexists then
                  zipquotaok = true
                else
                  zipquotaok = false
                end
              else
              end
          
              if @ethnicityquotavalidationwasdone then
                if ethnicityquotaexists then
                  ethnicityquotaok = true
                else
                  ethnicityquotaok = false
                end
              else
              end
          
              if @racequotavalidationwasdone then
                if racequotaexists then
                  racequotaok = true
                else
                  racequotaok = false
                end
              else
              end
          
              if @educationquotavalidationwasdone then
                if educationquotaexists then
                  educationquotaok = true
                else
                  educationquotaok = false
                end
              else
              end
          
              if @hhiquotavalidationwasdone then
                if hhiquotaexists then
                  hhiquotaok = true
                else
                  hhiquotaok = false
                end
              else
              end


              # if a validation was done and the below is true then the quota exists
          
              print '*********************Unnested Quota status: age, gender, zip, ethnicity, race, education and hhi: ', agequotaok, genderquotaok, zipquotaok, ethnicityquotaok, racequotaok, educationquotaok, hhiquotaok
              puts
          
              if (agequotaok && genderquotaok && zipquotaok && ethnicityquotaok && racequotaok && educationquotaok && hhiquotaok) then
                unnestedquotasexist = true
                puts 'unnested quota validation works out true'
              else
                unnestedquotasexist = false
                puts 'unnested quota validation does NOT work out true'
              end
            
              # if no questions matched and no validation was done then the following let sthe survey be included in the quota
              if (@agequotavalidationwasdone == false) &&
                (@genderquotavalidationwasdone == false) &&
                (@zipquotavalidationwasdone == false) &&
                (@ethnicityquotavalidationwasdone == false) &&
                (@racequotavalidationwasdone == false) &&
                (@educationquotavalidationwasdone == false) &&
                (@hhiquotavalidationwasdone == false) then
                unnestedquotasexist = true
            
                puts '********** Unnested quota declared available since no questions matched'
              else
              end
          

              # quota validation result for nested quota across all k sub-quotas of a survey
                # status of @listofunmatchednestedquestionIDs nil indicates that all quotas were matched
          
          
              # total quota validation result across all k sub-quotas of a survey
          
              if (@listofunmatchednestedquestionIDs.empty?) && (unnestedquotasexist) then
                # Everytime (Quota ID set of l quetions) a quota matches, capture the surveynumber. Delete duplicates later
                puts '****************** Adding the survey to the list of eligible surveys due to quota match'
                user.SurveysWithMatchingQuota << @surveynumber
            
            
                if (user.country == '9') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_US) then
            
                  @foundtopsurveyswithquota = true
          
                else
            
                  if (user.country == '6') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_CA) then
              
                    @foundtopsurveyswithquota = true
            
                  else
            
                    if (user.country == '5') && (user.SurveysWithMatchingQuota.uniq.length >= @p2s_AU) then
                
                      @foundtopsurveyswithquota = true
              
                    else
              
                      #do nothing
              
                    end
            
                  end
          
                end
            

              else
                print 'Quota in survey number = is not open for this user: ', @surveynumber
                puts
              end
          
          
          
            else #5          
              if totalquotaexists == false then #6
                #do nothing
              else #6
                # NumberOfQuotas (k) is 0 i.e. there are no quotas specified but totalquotacount exists.
                # The survey is open to All, provided there is need for respondents specified in Total
                puts '************* Adding survey to list of eligible quotas even though no quotas specified but Totalquotaexists.'
                user.SurveysWithMatchingQuota << @surveynumber
            
                if (user.country == '9') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_US) then
            
                  @foundtopsurveyswithquota = true
          
                else
            
                  if (user.country == '6') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_CA) then
              
                    @foundtopsurveyswithquota = true
            
                  else
            
                    if (user.country == '5') && (user.SurveysWithMatchingQuota.uniq.length >= @p2s_AU) then
                
                      @foundtopsurveyswithquota = true
              
                    else
              
                      #do nothing
              
                    end
            
                  end
          
                end
            
              end  # 6
            end #5 if there is quota specified in k = 0 (total) or more (other IDs)
          
          
#           end  #2 End reviewing quotas of a |survey|
# This end above is redundant since we did not need another survey loop in quotas - just used the one in quals.
       
#          end  #1 End j - going through the list of qualified surveys
           # delete this j-loop end      
        
#        end #0 End 'if' user did qualify for any survey(s)
    
    # delete this end above because quota check makes this check redundant
        
        
        
        
      else
        # This survey qualifications did not match with the user
        # Print for testing/verification
        
        @_gender = ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (( @GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )
        @_age = ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([user.age] & survey.QualificationAgePreCodes.flatten) == [user.age])
        @_age_value = [user.age] & survey.QualificationAgePreCodes.flatten
        @_ZIP = ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
        @_race = (( survey.QualificationRacePreCodes.empty? ) || ( survey.QualificationRacePreCodes.flatten == [ "ALL" ] ) || (([ user.race ] & survey.QualificationRacePreCodes.flatten) == [ user.race ]))
        @_ethnicity = (( survey.QualificationEthnicityPreCodes.empty? ) || ( survey.QualificationEthnicityPreCodes.flatten == [ "ALL" ] ) || (([ user.ethnicity ] & survey.QualificationEthnicityPreCodes.flatten) == [ user.ethnicity ]))
        @_education = (( survey.QualificationEducationPreCodes.empty? ) || ( survey.QualificationEducationPreCodes.flatten == [ "ALL" ] ) || (([ user.eduation ] & survey.QualificationEducationPreCodes.flatten) == [ user.eduation ]))
        @_HHI= (( survey.QualificationHHIPreCodes.empty? ) || ( survey.QualificationHHIPreCodes.flatten == [ "ALL" ] ) || (([ user.householdincome ] & survey.QualificationHHIPreCodes.flatten) == [ user.householdincome ]))
        @_employment = (( survey.QualificationEmploymentPreCodes.empty? ) || ( survey.QualificationEmploymentPreCodes.flatten == [ "ALL" ] ) || (([ user.employment ] & survey.QualificationEmploymentPreCodes.flatten) == [ user.employment ]))
        @_pindustry = (( survey.QualificationPIndustryPreCodes.empty? ) || ( survey.QualificationPIndustryPreCodes.flatten == [ "ALL" ] ) || (([ user.pindustry ] & survey.QualificationPIndustryPreCodes.flatten) == [ user.pindustry ]))        
        @_jobtitle = (( survey.QualificationJobTitlePreCodes.empty? ) || ( survey.QualificationJobTitlePreCodes.flatten == [ "ALL" ] ) || (([ user.jobtitle ] & survey.QualificationJobTitlePreCodes.flatten) == [ user.jobtitle ]))
        @_children = (( survey.QualificationChildrenPreCodes.empty? ) || ( survey.QualificationChildrenPreCodes.flatten == [ "ALL" ] ) || (( user.children  & survey.QualificationChildrenPreCodes.flatten).empty? == false)) 
        @_children_logic = user.children & survey.QualificationChildrenPreCodes.flatten  
        @_CPI_check = ((survey.CPI == nil) || (survey.CPI >= @currentpayout))

        
        
        print '************ User DID NOT QUALIFY for survey number = ', survey.SurveyNumber, ' RANK= ', survey.SurveyGrossRank, ' User enetered Gender: ', @GenderPreCode, ' Gender from Survey= ', survey.QualificationGenderPreCodes, ' USER ENTERED AGE= ', user.age, ' AGE PreCodes from Survey= ', survey.QualificationAgePreCodes, ' User Entered ZIP: ', user.ZIP, ' ZIP PreCodes from Survey: ....... ', ' User Entered Race: ', user.race, ' Race PreCode from survey: ', survey.QualificationRacePreCodes, ' User Entered ethnicity: ', user.ethnicity, ' Ethnicity PreCode from survey: ', survey.QualificationEthnicityPreCodes, ' User Entered education: ', user.eduation, ' Education PreCode from survey: ', survey.QualificationEducationPreCodes, ' User Entered HHI: ', user.householdincome, ' HHI PreCode from survey: ', survey.QualificationHHIPreCodes, ' User Entered Employment: ', user.employment, ' Std_Employment PreCode from survey: ', survey.QualificationEmploymentPreCodes, ' User Entered PIndustry: ', user.pindustry, ' PIndustry PreCode from survey: ', survey.QualificationPIndustryPreCodes, ' User Entered JobTitle: ', user.jobtitle, ' JobTitle PreCode from survey: ', survey.QualificationJobTitlePreCodes, ' User Entered Children: ', user.children, ' Children PreCodes from survey: ', survey.QualificationChildrenPreCodes, ' Network Payout: ', @currentpayout, ' CPI from survey: ', survey.CPI, ' SurveyStillAlive: ', survey.SurveyStillLive
         
        puts
        
        print '************** Gender match:', @_gender, ' Age match: ', @_age, ' Age_logic value: ', @_age_value, ' ZIP match: ', @_ZIP, ' Race match: ', @_race, ' Ethnicity match: ', @_ethnicity, ' Education match: ', @_education, ' HHI match: ', @_HHI, ' Employment match: ', @_employment, ' PIndustry match: ', @_pindustry, ' JobTitle match: ', @_jobtitle, ' Children match: ', @_children, ' Children_logic value: ', @_children_logic, ' CPI check: ', @_CPI_check
        puts
        
        if (survey.CountryLanguageID == 9) then
          
          @_DMA = (( survey.QualificationDMAPreCodes.empty? ) || ( survey.QualificationDMAPreCodes.flatten == [ "ALL" ] ) || (([ @DMARegionCode ] & survey.QualificationDMAPreCodes.flatten) == [ @DMARegionCode ]))
          @_State = (( survey.QualificationStatePreCodes.empty? ) || ( survey.QualificationStatePreCodes.flatten == [ "ALL" ] ) || (([ @statePrecode ] & survey.QualificationStatePreCodes.flatten) == [ @statePrecode ]))
          @_region = (( survey.QualificationRegionPreCodes.empty? ) || ( survey.QualificationRegionPreCodes.flatten == [ "ALL" ] ) || (([ @regionPrecode ] & survey.QualificationRegionPreCodes.flatten) == [ @regionPrecode ]))
          @_Division = (( survey.QualificationDivisionPreCodes.empty? ) || ( survey.QualificationDivisionPreCodes.flatten == [ "ALL" ] ) || (([ @divisionPrecode ] & survey.QualificationDivisionPreCodes.flatten) == [ @divisionPrecode ]))
                    
          print '************** DMA match: ', @_DMA, ' State match: ', @_State, ' Region match: ', @_region, ' Division match: ', @_Division
          puts
        else
        end
        
        
        
        if ((survey.CountryLanguageID == 5) || (survey.CountryLanguageID == 6)) && ( survey.QualificationZIPPreCodes.flatten != [ "ALL" ] ) then 
          print "______________________________________________________________________________________>> Disqualified due to CA or AU zipcode mismatch"
          print "ZIPs are ", survey.QualificationZIPPreCodes.flatten
          puts
        else
        end
          
          
          
        

        end # if survey meets qualification criteria or not
      
      else
      end #3 if @foundtopsurveyswithquota == false
    
    end # do loop for all surveys in db
    
    
    # Lets create the sequence of SupplierLinks refecting this priority of surveys and append the FED additional parameters
      
    if (user.SurveysWithMatchingQuota.empty?) then
      p '******************** RankFEDSurveys: No Surveys matching quota were found in Fulcrum'
#        redirect_to '/users/nosuccess'
#        return
    else       
      user.SurveysWithMatchingQuota = user.SurveysWithMatchingQuota.uniq
      print '*************** List of Fulcrum surveys where quota is available:', user.SurveysWithMatchingQuota
      puts
    end
      
    
    
    
    
     # If the user qualifies for one or more survey, send user to the top ranked survey first and repeat until success/failure/OT/QT
#     @InferiorSupplierLink = Array.new

    (0..user.SurveysWithMatchingQuota.length-1).each do |i| #do14
      @surveynumber = user.SurveysWithMatchingQuota[i]
      Survey.where( "SurveyNumber = ?", @surveynumber ).each do |survey| # do15

        # Eliminate surveys with EPC < 0.1
#        if survey.SurveyQuotaCalcTypeID != 5 then
          user.SupplierLink[i] = survey.SupplierLink["LiveLink"]
#        else        
          # Store the link in a separate container
#          @InferiorSupplierLink << survey.SupplierLink["LiveLink"]
#          print "Skipping survey number: ", @surveynumber, 'since its EPC: is < 0.1: ', survey.SurveyQuotaCalcTypeID
#          puts
#        end
      
      end #do15
    end #do14
    
    #Prevent a problem with userride if EPC < 0.1 eliminates ALL surveys

#    user.SupplierLink = user.SupplierLink + @InferiorSupplierLink
#    print '*********** USER HAS QUOTA FOR this list of Fulcrum surveys with EPC <0.1 moved to the end of the list:', user.SupplierLink
#    puts
    
    
    # Remove any blank entries
    if user.SupplierLink !=nil then
      user.SupplierLink.reject! { |c| c == nil}
    else
    end
    
    
    if (@netstatus == "INTTEST") then
      @PID = 'test'
    else
      @PID = user.user_id
    end
    
    
    if user.children != nil then
      @childrenvalue = '&Age_and_Gender_of_Child='+user.children[0]
      if user.children.length > 1 then
        (1..user.children.length-1).each do |i|
          @childrenvalue = @childrenvalue+'&Age_and_Gender_of_Child='+user.children[i]
        end
      else
      end
    else
      @childrenvalue = ''
    end    
    
    
    
    if user.country=="9" then 
      @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&ZIP='+user.ZIP+'&HISPANIC='+user.ethnicity+'&ETHNICITY='+user.race+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_US='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.employment+'&STANDARD_INDUSTRY_PERSONAL='+user.pindustry+'&STANDARD_JOB_TITLE='+user.jobtitle+@childrenvalue
    else
      if user.country=="6" then
        @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&ZIP_Canada='+user.ZIP.slice(0..2)+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_INT='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.employment+'&STANDARD_INDUSTRY_PERSONAL='+user.pindustry+'&STANDARD_JOB_TITLE='+user.jobtitle+@childrenvalue
      else
        if user.country=="5" then
          @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&Fulcrum_ZIP_AU='+user.ZIP+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_INT='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.employment+'&STANDARD_INDUSTRY_PERSONAL='+user.pindustry+'&STANDARD_JOB_TITLE='+user.jobtitle+@childrenvalue
        else
          if user.country=="7" then
            @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&Fulcrum_ZIP_IN='+user.ZIP+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_INT='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.employment+'&STANDARD_INDUSTRY_PERSONAL='+user.pindustry+'&STANDARD_JOB_TITLE='+user.jobtitle+@childrenvalue
          else
          end
        end
      end
    end    
    
    
    @parsed_user_agent = UserAgent.parse(user.user_agent)
    
    print "*************************************** RandFEDSurveys: User platform is: ", @parsed_user_agent.platform
    puts
    
    if @parsed_user_agent.platform == 'iPhone' then
      
      @MS_is_mobile = '&MS_is_mobile=true'
      p "*************************************** UserRide: MS_is_mobile is set TRUE"
      
    else
      @MS_is_mobile = '&MS_is_mobile=false'
      p "*************************************** UserRide: MS_is_mobile is set FALSE"
      
    end
    
    (0..user.SupplierLink.length-1).each do |i|
      user.SupplierLink[i] = user.SupplierLink[i]+@PID+@AdditionalValues+@MS_is_mobile
    end
    
    
    # Save the survey numbers that the user meets the qualifications and quota requirements for in this user's record of database in rank order
    
    user.save
    
    # Select RFG projects
    selectRfgProjects(session_id)  
      
  end # ranksurveys 
  
  def selectRfgProjects (session_id)
    
    user=User.find_by session_id: session_id
    
    @RFGclient = Network.find_by name: "RFG"
    if @RFGclient.status == "ACTIVE" then
      @rid = @RFGclient.netid+user.user_id
    
      print "**************** RFG @rid = ", @rid
      puts
     
    
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
         
    if user.country == '9' then
      user_country = "US"
    else
      if user.country == '6' then
        user_country = "CA"
      else
      end
    end
          
    # Initialize for the number of RFG projects to be included
    
    @foundtopprojectswithquota = false  
    @netid = user.netid
      
    if Network.where(netid: @netid).exists? then
      net = Network.find_by netid: @netid
        
        
        
        if net.payout == nil then
          @currentpayout = 1.49 # ensures breakeven at $1.25 payout
          @currentpayoutstr = "$"+@currentpayout.to_s
        else
          @currentpayout = net.payout  
          @currentpayoutstr = "$"+@currentpayout.to_s
        end
      
      
      
      
      
      
  
      if net.RFG_US != nil then
        if (net.RFG_US == 0) && (user.country == "9") then
          @foundtopprojectswithquota = true
          puts "**************** No RFG project is included "

        else
          @RFG_US = net.RFG_US
        end
      else
        @RFG_US = 0
        @foundtopprojectswithquota = true
      end
      
      if net.RFG_CA != nil then
        if (net.RFG_CA == 0) && (user.country == "6") then
          @foundtopprojectswithquota = true
          puts "**************** No RFG project is included "

        else
          @RFG_CA = net.RFG_CA
        end        
      else
        @RFG_CA = 0
        @foundtopprojectswithquota = true
      end
      
    else
      # Bad netid, Network is not known
      p '****************************** selectRFGProjects: ACCESS FROM AN UNRECOGNIZED NETWOK DENIED'
      redirect_to '/users/nosuccess'
      return
    end
    
    
    #Initialize an array to store qualified projects
    @RFGQualifiedProjects = Array.new
    @RFGProjectsWithQuota = Array.new
    @RFGSupplierLinks = Array.new
    
              
    RfgProject.where("country = ? AND state = ?", user_country, 2).order(projectEPC: :desc).order(epc: :desc).each do |project|

      if @foundtopprojectswithquota == false then  #3 false means not finished finding top projects
        
        print "*************** Checking qualifications for project number: ", project.rfg_id
        puts
        
        # Initialize qualificatio parameters true. These are turned false if user does not qualify
        @QualificationAge = true
        @QualificationGender = true
        @QualificationZip = true
        @QualificationHhi = true
        @QualificationPindustry = true
        @QualificationChildren = true
        @QualificationEducation = true
        @QualificationEmployment = true
        @QualificationDMA = true
        @QualificationState = true
        @QualificationRegion = true
     
        
        (0..project.datapoints.length-1).each do |m|
        
          case project.datapoints[m]["name"]
          when "Age"
            @QualificationAge = true
            (0..project.datapoints[m]["values"].length-1).each do |i|
              @QualificationAge = (project.datapoints[m]["values"][i]["min"]..project.datapoints[m]["values"][i]["max"]).include?(user.age.to_i) && @QualificationAge
            end
            print "User entered age: ", user.age
            puts
            print "Project qual age: ", project.datapoints[m]["values"]
            puts
            print "@QualificationAge: ", @QualificationAge
            puts
            
          when "Gender"
            if project.datapoints[m]["values"].length == 2 then
              @QualificationGender = true
            else
              if project.datapoints[m]["values"][0]["choice"] == user.gender.to_i then
                @QualificationGender = true
              else
                @QualificationGender = false
              end
            end
            print "User entered gender: ", user.gender
            puts
            print "Project qual gender: ", project.datapoints[m]["values"]
            puts
            print "@QualificationGender: ", @QualificationGender
            puts
            
          when "List of Zips"
            @QualificationZip = false
            (0..project.datapoints[m]["values"].length-1).each do |i|
             if (project.datapoints[m]["values"][i]["freelist"]).include?(user.ZIP) then 
               @QualificationZip = true
             else
             end
            end
            print "User entered zip: ", user.ZIP
            puts
            print "Project qual zip: ", project.datapoints[m]["values"]
            puts
            print "@QualificationZip: ", @QualificationZip
            puts
            
          when "List of FSAs (CA)"
            @QualificationZip = false
            (0..project.datapoints[m]["values"].length-1).each do |i|
              if (project.datapoints[m]["values"][i]["freelist"]).include?(user.ZIP.slice(0..2)) then 
                @QualificationZip = true
              else
              end
            end
            print "User entered zip: ", user.ZIP
            puts
            print "Project qual zip: ", project.datapoints[m]["values"]
            puts
            print "@QualificationZip: ", @QualificationZip
            puts
            
          when "STANDARD_HHI_US"
            @QualificationHhi = false
            (0..project.datapoints[m]["values"].length-1).each do |i|
              if project.datapoints[m]["values"][i]["choice"] == user.householdincome.to_i then
                @QualificationHhi = true
              else
              end
            end
            print "User entered HHI: ", user.householdincome
            puts
            print "Project qual HHI: ", project.datapoints[m]["values"]
            puts
            print "@QualificationHhi: ", @QualificationHhi
            puts
            
          when "STANDARD_HHI_INT"
            @QualificationHhi = false
            (0..project.datapoints[m]["values"].length-1).each do |i|
              if project.datapoints[m]["values"][i]["choice"] == user.householdincome.to_i then
                @QualificationHhi = true
              else
              end
            end
            print "User entered HHI: ", user.householdincome
            puts
            print "Project qual HHI: ", project.datapoints[m]["values"]
            puts
            print "@QualificationHhi: ", @QualificationHhi
            puts
              
          when "RFG2_Employment Industry Personal"
            @QualificationPindustry = false
            (0..project.datapoints[m]["values"].length-1).each do |i|
              if project.datapoints[m]["values"][i]["choice"] == user.pindustry.to_i then
                @QualificationPindustry = true
              else
              end
            end
            print "User entered Pindustry: ", user.pindustry
            puts
            print "Project qual Pindustry: ", project.datapoints[m]["values"]
            puts
            print "@QualificationPindustry: ", @QualificationPindustry
            puts
                  
          when "Children Age and Gender"
              @QualificationChildren = false
              (0..project.datapoints[m]["values"].length-1).each do |i|
                if ((project.datapoints[m]["values"][i]["choice"].to_s & user.children).empty? == false) then
                  @QualificationChildren = true
                else
                end
              end
              print "User entered Children: ", user.children
              puts
              print "Project qual Children: ", project.datapoints[m]["values"]
              puts
              print "@QualificationChildren: ", @QualificationChildren
              puts
                
          when "Education (US)"
              @QualificationEducation = false
              (0..project.datapoints[m]["values"].length-1).each do |i|
                if (project.datapoints[m]["values"][i]["choice"] <= 7) && ((project.datapoints[m]["values"][i]["choice"] == user.eduation.to_i)) then
                  @QualificationEducation = true
                  @RFGEducationUS = project.datapoints[m]["values"][i]["choice"].to_s
                else
                end                  
                if (project.datapoints[m]["values"][i]["choice"] == 7) && ((user.eduation.to_i == 8) || (user.eduation.to_i == 9) || (user.eduation.to_i == 10)) then
                  @QualificationEducation = true
                  @RFGEducationUS = project.datapoints[m]["values"][i]["choice"].to_s
                else
                end
                if (project.datapoints[m]["values"][i]["choice"] == 8) && (user.eduation.to_i == 11) then
                  @QualificationEducation = true
                  @RFGEducationUS = project.datapoints[m]["values"][i]["choice"].to_s
                else
                end
                if (project.datapoints[m]["values"][i]["choice"] == 9) && (user.eduation.to_i == 12) then
                  @QualificationEducation = true
                  @RFGEducationUS = project.datapoints[m]["values"][i]["choice"].to_s
                else
                end                    
              end
              print "User entered Education: ", user.eduation
              puts
              print "Project qual Education: ", project.datapoints[m]["values"]
              puts
              print "@QualificationEducation: ", @QualificationEducation
              puts
                  
          when "Education (CA)"
              @QualificationEducation = false
              (0..project.datapoints[m]["values"].length-1).each do |i|
              if (project.datapoints[m]["values"][i]["choice"] == 1) && (user.eduation.to_i == 1) then
                  @QualificationEducation = true
                  @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
              else
              end 
              if (project.datapoints[m]["values"][i]["choice"] == 2) && ((user.eduation.to_i == 2) || (user.eduation.to_i == 3)) then
                @QualificationEducation = true
                @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
              else
              end
              if (project.datapoints[m]["values"][i]["choice"] == 3) && (user.eduation.to_i == 4) then
                @QualificationEducation = true
                @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
              else
              end
              if (project.datapoints[m]["values"][i]["choice"] == 4) && ((user.eduation.to_i == 5) || (user.eduation.to_i == 6))  then
                @QualificationEducation = true
                @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
              else
              end
                    if (project.datapoints[m]["values"][i]["choice"] == 5) && ((user.eduation.to_i == 7) || (user.eduation.to_i == 8))  then
                      @QualificationEducation = true
                      @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
                    else
                    end
                    if (project.datapoints[m]["values"][i]["choice"] == 6) && (user.eduation.to_i == 9) then
                      @QualificationEducation = true
                      @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
                    else
                    end                    
                    if (project.datapoints[m]["values"][i]["choice"] == 7) && ((user.eduation.to_i == 10) || (user.eduation.to_i == 11))  then
                      @QualificationEducation = true
                      @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
                    else
                    end
                  end
                  print "User entered Education: ", user.eduation
                  puts
                  print "Project qual Education: ", project.datapoints[m]["values"]
                  puts
                  print "@QualificationEducation: ", @QualificationEducation
                  puts
                        
            when "Employment Status"
              @QualificationEmployment = false
              (0..project.datapoints[m]["values"].length-1).each do |i|
              if (project.datapoints[m]["values"][i]["choice"] == 1) && (user.employment.to_i == 10) then
                @QualificationEmployment = true
                @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
              else
              end 
                      if (project.datapoints[m]["values"][i]["choice"] == 2) && (user.employment.to_i == 2) then
                        @QualificationEmployment = true
                        @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
                      else
                      end
                      if (project.datapoints[m]["values"][i]["choice"] == 3) && (user.employment.to_i == 1) then
                        @QualificationEmployment = true
                        @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
                      else
                      end
                      if (project.datapoints[m]["values"][i]["choice"] == 4) && (user.employment.to_i == 7)  then
                        @QualificationEmployment = true
                        @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
                      else
                      end
                      if (project.datapoints[m]["values"][i]["choice"] == 5) && (user.employment.to_i == 9)  then
                        @QualificationEmployment = true
                        @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
                      else
                      end
                      if (project.datapoints[m]["values"][i]["choice"] == 6) && ((user.employment.to_i == 3) || (user.employment.to_i == 4)) then
                        @QualificationEmployment = true
                        @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
                      else
                      end                    
                      if (project.datapoints[m]["values"][i]["choice"] == 7) && (user.employment.to_i == 8)  then
                        @QualificationEmployment = true
                        @RFGEmployment = project.datapoints[n]["values"][i]["choice"].to_s
                      else
                      end
                    end
          print "User entered Employment: ", user.employment
          puts
          print "Project qual Employment: ", project.datapoints[m]["values"]
          puts
          print "@QualificationEmployment: ", @QualificationEmployment
          puts
          
        when "DMA (US)"
          @QualificationDMA = false
          (0..project.datapoints[m]["values"].length-1).each do |i|
            if project.datapoints[m]["values"][i]["choice"] == @DMARegionCode.to_i then
              @QualificationDMA = true
            else
            end
          end
          print "User entered DMA: ", @DMARegionCode
          puts
          print "Project qual DMA: ", project.datapoints[m]["values"]
          puts
          print "@QualificationDMA: ", @QualificationDMA
          puts
                    
        when "State (US)"
          @QualificationState = false
          (0..project.datapoints[m]["values"].length-1).each do |i|
            if project.datapoints[m]["values"][i]["choice"] == @StatePrecode.to_i then
              @QualificationState = true
            else
            end
          end
          print "User entered State: ", @StatePrecode
          puts
          print "Project qual State: ", project.datapoints[m]["values"]
          puts
          print "@QualificationState: ", @QualificationState
          puts
          
        when "Region (US)"
          @QualificationRegion = false
          (0..project.datapoints[m]["values"].length-1).each do |i|
            if project.datapoints[m]["values"][i]["choice"] == @regionPrecode.to_i then
              @QualificationRegion = true
            else
            end
          end
          print "User entered Region: ", @regionPrecode
          puts
          print "Project qual Region: ", project.datapoints[m]["values"]
          puts
          print "@QualificationRegion: ", @QualificationRegion
          puts          
          
          
        end # case statement
        end # do m
        
        
        print " QUALIFICATIONS CRITERIA for: ", project.rfg_id
        puts
        print "country = ", (project.country == "CA") || (project.country == "US")
        puts
        print "cpi = ", (project.cpi > @currentpayoutstr)
        puts        
        print "Live = ", (project.projectStillLive)
        puts
        print "Age = ", (@QualificationAge)
        puts
        print "Gender = ", (@QualificationGender)
        puts
        print "Zip = ", (@QualificationZip)
        puts
        print "HHI = ", (@QualificationHhi)
        puts
        print "PIndustry = ", (@QualificationPindustry)
        puts
        print "Education = ", (@QualificationEducation)
        puts
        print "Employment = ", (@QualificationEmployment)
        puts
        print "Children = ", (@QualificationChildren)
        puts
        print "DMA = ", (@QualificationDMA)
        puts
        print "State = ", (@QualificationState)
        puts
        print "Region = ", (@QualificationRegion)
        puts
        
        
        
        
        if ( (project.country == "CA") && ( project.projectStillLive ) && (project.cpi > @currentpayoutstr) && ( @QualificationAge ) && ( @QualificationGender ) && ( @QualificationZip ) && ( @QualificationHhi ) && ( @QualificationPindustry ) && ( @QualificationEducation ) && ( @QualificationEmployment ) && (@QualificationChildren) ) ||
          
          ( (project.country == "US") && ( project.projectStillLive ) && (project.cpi > @currentpayoutstr) && ( @QualificationAge ) && ( @QualificationGender ) && ( @QualificationZip ) && ( @QualificationHhi ) && ( @QualificationPindustry ) && ( @QualificationEducation ) && ( @QualificationEmployment ) && (@QualificationChildren) && (@QualificationDMA) && (@QualificationState) && (@QualificationRegion) )          
          then
          
          @RFGQualifiedProjects << project.rfg_id
          
          print '********** In total USER_ID: ', user.user_id, ' has QUALIFIED for the following RFG projects: ', @RFGQualifiedProjects
          puts
          

          # Verify if there is a quota for the qualified user and if it is full
          
          if project.quotas.length > 0 then          
            # @RFGQuotaIsAvailable = false # initialize quota availability as false, then check quotas to prove/disprove
           # @RFGQuotaFull = false
            
            
            
          
            (0..project.quotas.length-1).each do |j|
              (0..project.quotas[j]["datapoints"].length-1).each do |n|
            
              # Assume quota per qualifications is available. These are turned false if user does not qualify
              @QualificationAge = true
              @QualificationGender = true
              @QualificationZip = true
              @QualificationHhi = true
              @QualificationPindustry = true
              @QualificationChildren = true
              @QualificationEducation = true
              @QualificationEmployment = true
              @QualificationDMA = true
              @QualificationState = true
              @QualificationRegion = true
              
                                        
              case project.quotas[j]["datapoints"][n]["name"]
              when "Age"
                @QualificationAge = true
                (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                  @QualificationAge = (project.quotas[j]["datapoints"][n]["values"][i]["min"]..project.quotas[j]["datapoints"][n]["values"][i]["max"]).include?(user.age.to_i) && @QualificationAge
                end
                print "User entered age: ", user.age
                puts
                print "Project qual age: ", project.quotas[j]["datapoints"][n]["values"]
                puts
                print "@QualificationAge: ", @QualificationAge
                puts
            
              when "Gender"
                if project.quotas[j]["datapoints"][n]["values"].length == 2 then
                  @QualificationGender = true
                else
                  if project.quotas[j]["datapoints"][n]["values"][0]["choice"] == user.gender.to_i then
                    @QualificationGender = true
                  else
                    @QualificationGender = false
                  end
                end
                print "User entered gender: ", user.gender
                puts
                print "Project qual gender: ", project.quotas[j]["datapoints"][n]["values"]
                puts
                print "@QualificationGender: ", @QualificationGender
                puts
            
              when "List of Zips"
                @QualificationZip = false
                (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                 if (project.quotas[j]["datapoints"][n]["values"][i]["freelist"]).include?(user.ZIP) then 
                   @QualificationZip = true
                 else
                 end
                end
                print "User entered zip: ", user.ZIP
                puts
                print "Project qual zip: ", project.quotas[j]["datapoints"][n]["values"]
                puts
                print "@QualificationZip: ", @QualificationZip
                puts
            
              when "List of FSAs (CA)"
                @QualificationZip = false
                print "Project qual zip: ", project.quotas[j]["datapoints"][n]["values"]
                puts
                (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                  if (project.quotas[j]["datapoints"][n]["values"][i]["freelist"]).include?(user.ZIP.slice(0..2)) then 
                    @QualificationZip = true
                  else
                  end
                end
                print "User entered zip: ", user.ZIP
                puts
                
                print "@QualificationZip: ", @QualificationZip
                puts
            
              when "STANDARD_HHI_US"
                @QualificationHhi = false
                (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                  if project.quotas[j]["datapoints"][n]["values"][i]["choice"] == user.householdincome.to_i then
                    @QualificationHhi = true
                  else
                  end
                end
                print "User entered HHI: ", user.householdincome
                puts
                print "Project qual HHI: ", project.quotas[j]["datapoints"][n]["values"]
                puts
                print "@QualificationHhi: ", @QualificationHhi
                puts
            
              when "STANDARD_HHI_INT"
                @QualificationHhi = false
                (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                  if project.quotas[j]["datapoints"][n]["values"][i]["choice"] == user.householdincome.to_i then
                    @QualificationHhi = true
                  else
                  end
                end
                print "User entered HHI: ", user.householdincome
                puts
                print "Project qual HHI: ", project.quotas[j]["datapoints"][n]["values"]
                puts
                print "@QualificationHhi: ", @QualificationHhi
                puts
              
              when "RFG2_Employment Industry Personal"
                @QualificationPindustry = false
                (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                  if project.quotas[j]["datapoints"][n]["values"][i]["choice"] == user.pindustry.to_i then
                    @QualificationPindustry = true
                  else
                  end
                end
                print "User entered Pindustry: ", user.pindustry
                puts
                print "Project qual Pindustry: ", project.quotas[j]["datapoints"][n]["values"]
                puts
                print "@QualificationPindustry: ", @QualificationPindustry
                puts
                  
              when "Children Age and Gender"
                  @QualificationChildren = false
                  (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                    if ((project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s & user.children).empty? == false) then
                      @QualificationChildren = true
                    else
                    end
                  end
                  print "User entered Children: ", user.children
                  puts
                  print "Project qual Children: ", project.quotas[j]["datapoints"][n]["values"]
                  puts
                  print "@QualificationChildren: ", @QualificationChildren
                  puts
                
              when "Education (US)"
                  @QualificationEducation = false
                  (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                    if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] <= 7) && ((project.quotas[j]["datapoints"][n]["values"][i]["choice"] == user.eduation.to_i)) then
                      @QualificationEducation = true
                      @RFGEducationUS = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                    else
                    end                  
                    if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && ((user.eduation.to_i == 8) || (user.eduation.to_i == 9) || (user.eduation.to_i == 10)) then
                      @QualificationEducation = true
                      @RFGEducationUS = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                    else
                    end
                    if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 8) && (user.eduation.to_i == 11) then
                      @QualificationEducation = true
                      @RFGEducationUS = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                    else
                    end
                    if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 9) && (user.eduation.to_i == 12) then
                      @QualificationEducation = true
                      @RFGEducationUS = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                    else
                    end                    
                  end
                  print "User entered Education: ", user.eduation
                  puts
                  print "Project qual Education: ", project.quotas[j]["datapoints"][n]["values"]
                  puts
                  print "@QualificationEducation: ", @QualificationEducation
                  puts
                  
              when "Education (CA)"
                  @QualificationEducation = false
                  (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                  if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && (user.eduation.to_i == 1) then
                      @QualificationEducation = true
                      @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                  else
                  end 
                  if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && ((user.eduation.to_i == 2) || (user.eduation.to_i == 3)) then
                    @QualificationEducation = true
                    @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                  else
                  end
                  if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && (user.eduation.to_i == 4) then
                    @QualificationEducation = true
                    @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                  else
                  end
                  if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && ((user.eduation.to_i == 5) || (user.eduation.to_i == 6))  then
                    @QualificationEducation = true
                    @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                  else
                  end
                        if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && ((user.eduation.to_i == 7) || (user.eduation.to_i == 8))  then
                          @QualificationEducation = true
                          @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                        else
                        end
                        if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && (user.eduation.to_i == 9) then
                          @QualificationEducation = true
                          @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                        else
                        end                    
                        if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && ((user.eduation.to_i == 10) || (user.eduation.to_i == 11))  then
                          @QualificationEducation = true
                          @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                        else
                        end
                      end
                      print "User entered Education: ", user.eduation
                      puts
                      print "Project qual Education: ", project.quotas[j]["datapoints"][n]["values"]
                      puts
                      print "@QualificationEducation: ", @QualificationEducation
                      puts
                        
                when "Employment Status"
                  @QualificationEmployment = false
                  (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                  if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && (user.employment.to_i == 10) then
                    @QualificationEmployment = true
                    @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                  else
                  end 
                          if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && (user.employment.to_i == 2) then
                            @QualificationEmployment = true
                            @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                          else
                          end
                          if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && (user.employment.to_i == 1) then
                            @QualificationEmployment = true
                            print "----------->>> project employment choice: ", project.quotas[j]["datapoints"][n]["values"][i]["choice"], 'and user.employment: ', user.employment
                            puts 
                            @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                          else
                          end
                          if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && (user.employment.to_i == 7)  then
                            @QualificationEmployment = true
                            @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                          else
                          end
                          if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && (user.employment.to_i == 9)  then
                            @QualificationEmployment = true
                            @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                          else
                          end
                          if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && ((user.employment.to_i == 3) || (user.employment.to_i == 4)) then
                            @QualificationEmployment = true
                            @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                          else
                          end                    
                          if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && (user.employment.to_i == 8)  then
                            @QualificationEmployment = true
                            @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
                          else
                          end
                        end
              print "User entered Employment: ", user.employment
              puts
              print "Project qual Employment: ", project.quotas[j]["datapoints"][n]["values"]
              puts
              print "@QualificationEmployment: ", @QualificationEmployment
              puts
          
            when "DMA (US)"
              @QualificationDMA = false
              (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                if project.quotas[j]["datapoints"][n]["values"][i]["choice"] == @DMARegionCode.to_i then
                  @QualificationDMA = true
                else
                end
              end
              print "User entered DMA: ", @DMARegionCode
              puts
              print "Project qual DMA: ", project.quotas[j]["datapoints"][n]["values"]
              puts
              print "@QualificationDMA: ", @QualificationDMA
              puts
                    
            when "State (US)"
              @QualificationState = false
              (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                if project.quotas[j]["datapoints"][n]["values"][i]["choice"] == @StatePrecode.to_i then
                  @QualificationState = true
                else
                end
              end
              print "User entered State: ", @StatePrecode
              puts
              print "Project qual State: ", project.quotas[j]["datapoints"][n]["values"]
              puts
              print "@QualificationState: ", @QualificationState
              puts
          
            when "Region (US)"
              @QualificationRegion = false
              (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                if project.quotas[j]["datapoints"][n]["values"][i]["choice"] == @regionPrecode.to_i then
                  @QualificationRegion = true
                else
                end
              end
              print "User entered Region: ", @regionPrecode
              puts
              print "Project qual Region: ", project.quotas[j]["datapoints"][n]["values"]
              puts
              print "@QualificationRegion: ", @QualificationRegion
              puts          
              end # case statement
              
              
              print " QUOTA AVAILABILITY CRITERIA for: ", project.rfg_id
              puts
              print "country = ", (project.country == "CA") || (project.country == "US")
              puts
              print "Age = ", (@QualificationAge)
              puts
              print "Gender = ", (@QualificationGender)
              puts
              print "Zip = ", (@QualificationZip)
              puts
              print "HHI = ", (@QualificationHhi)
              puts
              print "PIndustry = ", (@QualificationPindustry)
              puts
              print "Education = ", (@QualificationEducation)
              puts
              print "Employment = ", (@QualificationEmployment)
              puts
              print "Children = ", (@QualificationChildren)
              puts
              print "DMA = ", (@QualificationDMA)
              puts
              print "State = ", (@QualificationState)
              puts
              print "Region = ", (@QualificationRegion)
              puts
              
              
              
              if ( (project.country == "CA") && ( @QualificationAge ) && ( @QualificationGender ) && ( @QualificationZip ) && ( @QualificationHhi ) && ( @QualificationPindustry ) && ( @QualificationEducation ) && ( @QualificationEducation ) && (@QualificationEmployment) && (@QualificationChildren) ) then
                
                if project.quotas[j]["completesLeft"] > 0 then
              
                @RFGQuotaIsAvailable = true
              else
                # if previous quota was available then preserve that fact
                @RFGQuotaIsAvailable = false
                # @RFGQuotaFull = true
              end
            else
            end
              
              if ( (project.country == "US") && ( @QualificationAge ) && ( @QualificationGender ) && ( @QualificationZip ) && ( @QualificationHhi ) && ( @QualificationPindustry )  && ( @QualificationEducation ) && ( @QualificationEmployment ) && (@QualificationEducation) && (@QualificationChildren) && (@QualificationDMA) && (@QualificationState) && (@QualificationRegion)  ) then
                
                if project.quotas[j]["completesLeft"] > 0 then
              
                @RFGQuotaIsAvailable = true
              else
                # if previous quota was available then preserve that fact
                @RFGQuotaIsAvailable = false
                # @RFGQuotaFull = true
              end
              
            else
            end
              
            end # reviewed all n nested qualifications of a quota
                           
            end # all j quotas have been inspected

          else
            @RFGQuotaIsAvailable = true 
            # @RFGQuotaFull = false
            
            print "************** Quota available: There are no quota restrictions"
            puts
          end
          
#           if @RFGQuotaFull == false then
          if @RFGQuotaIsAvailable == true then
          
            print '********** USER_ID: ', user.user_id, ' has Quota for the RFG project: ', project.rfg_id
            puts

            @RFGProjectsWithQuota << project.rfg_id
            @RFGSupplierLinks << project.link+'&rfg_id='+project.rfg_id
                        
            
            if (user.country == '9') && (@RFGProjectsWithQuota.uniq.length >= @RFG_US) then
          
              @foundtopprojectswithquota = true
        
            else
          
              if (user.country == '6') && (@RFGProjectsWithQuota.uniq.length >= @RFG_CA) then
            
                @foundtopprojectswithquota = true
          
              else
          
                #do nothing
          
              end
        
            end
            
            
          else
            
            print '********** USER_ID: ', user.user_id, ' DOES NOT HAVE ANY Quota available for the RFG projects: ', project.rfg_id
            puts
          end
          
        else
          
          print '************ User DID NOT QUALIFY for project number = ', project.rfg_id
          puts
          
        end # Qualification check
        
      else
      end # if foundtopprojects
      
    end # do all projects

      
    print '********** In total USER_ID: ', user.user_id, ' has Quota available for the RFG projects: ', @RFGProjectsWithQuota
    puts
      
    print '********** Total SUPPLIERLINKS for the RFG projects user has quota are: ', @RFGSupplierLinks
    puts
      
      
    # Assemble additional parameters valuses to pass with the entry link
      
    if user.children != nil then
      @RFGchildrenvalue = '&ChildrenAgeGender='+user.children[0]
      if user.children.length > 1 then
        (1..user.children.length-1).each do |i|
          @RFGchildrenvalue = @RFGchildrenvalue+'&ChildrenAgeGender='+user.children[i]
        end
      else
      end
    else
      @RFGchildrenvalue = ''
    end
      
      
    if @RFGEmployment == nil then        
      @RFGEmployment = ''
    else
    end
    
    if @RFGEducationUS == nil then        
      @RFGEducationUS = ''
    else
    end 
    
    if @RFGEducationCA == nil then        
      @RFGEducationCA = ''
    else
    end 
     
      
      
    if user.country=="9" then 
      @RFGAdditionalValues = '&rid='+@rid+'&country=US'+'&postalCode='+user.ZIP+'&gender='+user.gender+'&age='+user.age+'&rfg2_14785='+user.householdincome+'&employment='+@RFGEmployment+'&educationUS='+@RFGEducationUS+@RFGchildrenvalue
    else
      if user.country=="6" then
          @RFGAdditionalValues = '&rid='+@rid+'&country=CA'+'&postalCode='+user.ZIP+'&gender='+user.gender+'&age='+user.age+'&educationCA='+@RFGEducationCA+'&rfg2_14887='+user.householdincome+'&employment='+@RFGEmployment+@RFGchildrenvalue
      else
      end
    end    
      
    if @parsed_user_agent.platform == 'iPhone' then
      
      @MS_is_mobile = '&MS_is_mobile=true'
      p "*************************************** RankRFGProjects: MS_is_mobile is set TRUE"
      
    else
      @MS_is_mobile = '&MS_is_mobile=false'
      p "*************************************** RankRFGProjects: MS_is_mobile is set FALSE"
      
    end
      
    if @RFGSupplierLinks != nil then
      (0..@RFGSupplierLinks.length-1).each do |i|
        @RFGSupplierLinks[i] = @RFGSupplierLinks[i]+@RFGAdditionalValues+@MS_is_mobile
      end
      print "************ RFGSupplierLinks List: ", @RFGSupplierLinks
      puts
      
    else
      # do nothing, no RFG surveys natch the user
      puts "************ User did not match any available quota in RFG projects"
    end
    
    
    
    else
    # do nothing for RFG
    end # RFG status is ACTIVE
    
    
    # Begin the ride
    userride (session_id)      
        
  end #selectRfgProjects
       
  def userride (session_id)
    
    user = User.find_by session_id: session_id
    @PID = user.user_id

    # If user is blacklisted, then qterm
    if user.black_listed == true then
      print '******************** UserID is BLACKLISTED: ', user.user_id
      puts
      redirect_to '/users/nosuccess'
      return
    else
    end
       
    # FED or RFG go first
    
    if (@RFGIsBack) then
      user.SupplierLink << @RFGSupplierLinks
      puts "RFG is Back"
    else
      if (@RFGIsFront) then
        puts "RFG is Front"
        if user.SupplierLink == nil then
          user.SupplierLink = @RFGSupplierLinks
        else
          if @RFGSupplierLinks == nil then
            #do nothing
          else
            @tmp = user.SupplierLink
            user.SupplierLink = @RFGSupplierLinks + @tmp
          end
        end
      else
        # do nothing and RFG will not be included
        puts "*************** RFG is not included"
      end
    end
    
    # Save the order of FED and RFG
    
    user.save
    
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
    
      print "**************** P2S @SUID = ", @SUBID
      puts

      if user.gender == '1' then
        @p2s_gender = "m"
      else
        @p2s_gender = "f"
      end
             
      
      p2s_hispanic = [0, 6729, 6730, 6898, 6900, 6901, 6902, 6903, 6904, 6905, 6906, 6907, 6908, 6909, 6910, '']
      @p2s_hispanic = p2s_hispanic[user.ethnicity.to_i].to_s
      
      p2s_employment_status = [0, 7007, 7008, 7006, 7006, 7013, 7013, 7012, 7011, 7009, 7010, 7009, '']
      @p2s_employment_status = p2s_employment_status[user.employment.to_i].to_s
      
      
      p2s_income_level = [0, 9089, 9089, 9089, 9071, 9072, 9088, 9073, 9087, 9074, 9086, 9090, 9075, 9091, 9076, 9092, 9077, 9093, 9078, 9094, 9079, 9080, 9081, 9082, 9085, 9084, 9084, '']
      @p2s_income_level = p2s_income_level[user.householdincome.to_i].to_s
      
      
      p2s_race = [0, 10094, 10095, 10101, 10097, 10098, 10104, 10109, 10110, 10111, 10096, 10102, 10106, 10107, 10108, 10103, '']
      @p2s_race = p2s_race[user.race.to_i].to_s
      
      p2s_education_level = [0, 10157, 10157, 10157, 10158, 10163, 10159, 10160, 10161, 10165, 10162, 10164, '']
      @p2s_education_level = p2s_education_level[user.eduation.to_i].to_s
      
      p2s_org_id = [0, 22942, 22934, '', '', 22936, '', 22942, '', '', 22938, '', 22957, 22957, 22957, 22957, 22938, '', '', 22939, 22940, '', '', '', '', '', 22943, 22944, 22945, '', 22957, '', '', 22946, 22947, 22949, 22948, 22950, '', 22952, '', 22944, 22953, '', 22954, '', '', '', '', '', 22959, '']
      @p2s_org_id = p2s_org_id[user.pindustry.to_i].to_s
      
      p2s_jobtitle = [0, 14899, 14900, 14901, 14902, 14903, 14904, 14905, 14906, 14907, 14908, 14909]
      @p2s_jobtitle = p2s_jobtitle[user.jobtitle.to_i].to_s
      
      
      p2s_children = [0, '', '', '', '', '', '', 6975, 6976, 6977, 6978, 6979, 6980, 6981, 6982, 6983, 6984, 6985, 6986, 6987, 6988, 6989, 6990, 6991, 6992, 6993, 6994, 6995, 6996, 6997, 6998, 6999, 7000, 7001, 7002, 7003, 7004, 7005]
      
      
      if user.children != nil then
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
      end
      


      # p2s additional values

      if user.country=="9" then
        @p2s_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP+'&employment_status='+@p2s_employment_status+'&income_level='+@p2s_income_level+'&education_level='+@p2s_education_level+'&hispanic='+@p2s_hispanic+'&race='+@p2s_race+'&org_id='+@p2s_org_id+'&job_title='+@p2s_jobtitle+'&children_under_18='+@p2s_children
      else
        if user.country=="6" then
          @p2s_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP+'&employment_status='+@p2s_employment_status+'&education_level='+@p2s_education_level+'&org_id='+@p2s_org_id+'&job_title='+@p2s_jobtitle+'&children_under_18='+@p2s_children
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
      
      @p2sSupplierLink = 'http://www.your-surveys.com/?si=55&ssi='+@SUBID+'&'+@p2s_AdditionalValues+'&hmac='+@hmac
      
      print "**************P2S SupplierLink = ", @p2sSupplierLink
      puts
      
      user.SupplierLink << @p2sSupplierLink
      
      # Save the list of SupplierLinks with P2S, if ACTIVE
    
      user.save

    else
      puts "********************** P2S is not attached"
    end #if P2SisAttached 

    # Start the ride
    
    if user.SupplierLink.length == 0 then
      redirect_to '/users/nosuccess'
    else      

      if user.SupplierLink[0] == @p2sSupplierLink then
      
        print '*************** User will be sent to P2S router as no other surveys are available: ', user.SupplierLink[0]
        puts
      
        @EntryLink = user.SupplierLink[0]
        user.SupplierLink = user.SupplierLink.drop(1)
        user.save
        redirect_to @EntryLink
      
      else
      
        print '***************** User will be sent to this survey: ', user.SupplierLink[0]
        puts
    
        @EntryLink = user.SupplierLink[0]
#      @EntryLink = user.SupplierLink[0]+@PID+@AdditionalValues
        user.SupplierLink = user.SupplierLink.drop(1)
        user.save
        redirect_to @EntryLink
      
      end # if user.SupplierLink[0] == @p2sSupplierLink then
      
    end # if user.SupplierLink == nil
    
  end
  
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
    print '****************************** CID= ', user.clickid, ' NetId= ', user.netid
    puts
    
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
     @RadiumOnePostBack = HTTParty.post('panel.gwallet.com/network-node/postback/ketsciinc?sid='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
       rescue HTTParty::Error => e
      puts 'HttParty::Error '+ e.message
       retry
   end while @RadiumOnePostBack.code != 200

  else
  end
  
  
  
  # Keep a count of Test completes on each Network
  
  puts "*************** Keeping track of Test completes on each network"
  
 
  @net = Network.find_by netid: user.netid

  if @net.Flag4 == nil then
    @net.Flag4 = "1" 
  else
    @net.Flag4 = (@net.Flag4.to_i + 1).to_s
  end
  
  @net.save
  
  
  # Save Test completed information by user
  
  if user.netid == "BAiuy55520xzLwL2rtwsxcAjklHxsdh" then 
    @net_name = "SuperSonic"
  else
  end
  
  if user.netid == "Aiuy56420xzLL7862rtwsxcAHxsdhjkl" then 
    @net_name = "Fyber"
  else
  end
    
    user.SurveysAttempted << 'TESTSURVEY'
    user.SurveysCompleted[user.user_id] = [Time.now, 'TESTSURVEY', user.clickid, @net_name]
    user.save
    
    redirect_to '/users/successful'
  end

end