class UsersController < ApplicationController

  require 'mixpanel-ruby'
  require 'hmac-md5'

  def new
  end

  def show
  end
  
  def create
  end
    
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
      
 #     if (netid == "CyAghLwsctLL98rfgyAHplqa1iuytIA") ||  (netid == "Aiuy56420xzLL7862rtwsxcAHxsdhjkl") || (netid == "BAiuy55520xzLwL2rtwsxcAjklHxsdh") then
  #      @country = "US"
  #    else
        
  #      @country = request.location.country_code
  #      print "--------------------------->> Geocoder COUNTRY = ", @country
  #      puts
   #   end
      

  #    if @country == "US" then
  #      @countryPrecode = "9"
  #      print "--------------------------->> @countryPrecode = ", @countryPrecode
  #      puts
  #    else
  #      if @country == "CA" then
  #        @countryPrecode = "6"
  #        print "--------------------------->> @countryPrecode = ", @countryPrecode
  #        puts
  #      else
  #        if @country == "AU" then
  #          @countryPrecode = "5"
  #          print "--------------------------->> @countryPrecode = ", @countryPrecode
  #          puts
  #        else
  #          @countryPrecode = "9"
  #          print "--------------------------->> **** DEFAULT **** @countryPrecode = ", @countryPrecode
  #          puts
  #        end
  #      end
  #    end
      
      
      # Keep track of clicks on each network as Flag2
      
      if netid != nil then
        @SSnet = Network.find_by netid: netid
        if @SSnet == nil then
          print "************************************ Bad NetworkId ********************"
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
#        p '****************** EVAL_AGE: Creating new record for FIRST TIME USER'
        #  @user = User.new(user_params)
        @user = User.new
        @user.age = @age
        @user.netid = netid
        @user.clickid = clickid
        @user.country = @countryPrecode
        
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
        user = User.where("ip_address = ? AND session_id = ?", ip_address, session_id).first
      #  p user

        # Why do I have to stop at first? Optimizes. But there should be not more than 1 entry.

        if user.black_listed==true then
          p '******************* EVAL_AGE: REPEAT USER is Black listed'
          userride (session_id)
        else
          p '******************* EVAL_AGE: Modifying existing user record of a REPEAT USER'

          user.age = @age
          user.netid = netid
          user.clickid = clickid
          user.country = @countryPrecode     
               
          # These get a blank entry on the list due to save action?
          user.QualifiedSurveys = []
          user.SurveysWithMatchingQuota = []
          user.SupplierLink = []
          user.session_id = session.id
          user.tos = false
          user.attempts_time_stamps_array = user.attempts_time_stamps_array + [Time.now]
          user.number_of_attempts_in_last_24hrs=user.attempts_time_stamps_array.count { |x| x > (Time.now-1.day) }
          user.save
          redirect_to '/users/tos'
        end
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
        p '******* Too many attempts to take a survey ***********'
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
      
#      if user.country=="9" then 
#        redirect_to '/users/qq4_US'
#      else
#        if user.country=="6" then
#          redirect_to '/users/qq4_CA'
#        else
#          if user.country=="5" then
#            redirect_to '/users/qq4_AU'
#          else
#            if user.country=="7" then
#              redirect_to '/users/qq4_IN'
#            else
#              if user.country=="0" then
#               redirect_to '/users/nosuccess'
#              else
#               redirect_to '/users/qq4_US'
#              end
#            end
#          end
#        end
#      end     
      
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
    
  def householdcomp  

#    user=User.find_by session_id: session.id
###    user.householdcomp=params[:householdcomp][:range]
#    user.householdcomp=params[:householdcomp]
#    user.save
#    ranksurveysforuser(session.id)
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
    
    print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++a ", user.user_id, " of ", user.country, " Time 2 start FED search: ", Time.now
    puts
    
    ranksurveysforuser(session.id)
    
  end

  def join_panel  

    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id

    tracker.track(user.ip_address, 'newpanelist')

    if params[:emailid].empty? == false then
      user.emailId = params[:emailid]
      user.save
      tracker.track(user.ip_address, 'panelistregistered')
      redirect_to '/users/thanks'
    else
      redirect_to '/users/thanks'
    end
  end

  
  # start to rankfedsurveys

  def ranksurveysforuser (session_id)

    require 'base64'
    require 'hmac-sha1'
    @SHA1key = 'uhstarvsuio765jalksrWE'


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

    # Lets find surveys that user is qualified for.
      
    # If this is a TEST e.g. with a network provider then route user to run the standard test survey.

    @netid = user.netid
    @poorconversion = false
      
    if Network.where(netid: @netid).exists? then
      net = Network.find_by netid: @netid
        
      if net.payout == nil then
        @currentpayout = 1.85 # assumes this is the minimum payout for FED surveys across networks including the 30% fees
      else
        @currentpayout = 1.44*net.payout # FED CPI must be higher than net.payout + 30% of survey CPI. This approximation with 30% of net.payout is a good approximation.
        p '****************************** minimum payout for FED set to: ', @currentpayout
        puts
      end
             
             
      if (net.status == "EXTTEST") then
        puts "***********EXTTEST FOUND ***************"
        redirect_to '/users/techtrendssamplesurvey'
        return
      else
        if (net.status == "INACTIVE") then
          p '****************************** ACCESS FROM AN INACTIVE NETWOK DENIED'
          puts
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
    
    
    # if net.stackOrder != nil then
    #   if (net.stackOrder == "RFGISFRONT") then
    #     @RFGIsFront = true
    #     puts "**************** RFG IS ahead of FED"
            
    #   else
    #     if (net.stackOrder == "RFGISBACK") then
    #       @RFGIsBack = true
    #       puts "**************** RFG IS at the Back of FED"
              
    #     else
    #       if (net.stackOrder == "RFGISOFF") then
    #         @RFGIsOff = true
    #         puts "**************** RFG IS OFF"
    #       else
    #       end    
    #     end
    #   end
    # else
    #   @RFGIsOff = true
    # end





if net.stackOrder != nil then
  if (net.stackOrder == ("ARFP" || "RAFP" || "RFAP" || "RFP")) then
    @RFGIsFront = true
    puts "**************** RFG is ahead of FED"        
  else
    if (net.stackOrder == ("AFRP" || "FARP" || "FRAP" || "FRP")) then
      @RFGIsBack = true
      puts "**************** RFG is after FED"          
    else
      if (net.stackOrder.exclude?("R")) then
        @RFGIsOff = true
        puts "**************** RFG is OFF since net.stackOrder = ", net.stackOrder
      else
      end    
    end
  end
else
  @RFGIsOff = true
end














    
    # Set the priority for P2S stack
        
    @foundtopsurveyswithquota = false   # false means not finished finding top FED surveys (set it to true if testing p2s)
        
    if net.FED_US != nil then
      if (net.FED_US == 0) && (user.country == "9") then
        @foundtopsurveyswithquota = true # true takes users to the next stackOrder

      else
        @fed_US = net.FED_US
      end
    else
      @fed_US = 1
    end
      
    if net.FED_CA != nil then
      if (net.FED_CA == 0) && (user.country == "6") then
        @foundtopsurveyswithquota = true # true takes users to the next stackOrder
        
      else
        @fed_CA = net.FED_CA
      end        
    else
      @fed_CA = 1
    end
      
    if net.FED_AU != nil then
      if (net.FED_AU == 0) && (user.country == "5") then
        @foundtopsurveyswithquota = true # true takes users to the next stackOrder

      else
        #@p2s_AU = net.FED_AU
        @fed_AU = net.FED_AU
      end        
    else
      #@p2s_AU = 1
      @fed_AU = 1
    end
    
    if @poorconversion then
      @topofstack = 1
    else
      # make top of Custom surveys as starting spot for picking qualified surveys
      @topofstack = 1
    end

    print "**************************** PoorConversion is turned: ", @poorconversion, ' Topofstack is: ', @topofstack
    puts

    puts "**************************** STARTING SEARCH FOR FED SURVEYS USER QUALIFIES FOR"
    
    # change countrylanguageid setting to match user countryID only
    @usercountry = (user.country).to_i

    # Survey.where("CountryLanguageID = ? AND SurveyGrossRank >= ?", @usercountry, @topofstack).order( "SurveyGrossRank" ).each do |survey|
    Survey.where("CountryLanguageID = ? AND SurveyGrossRank < ? AND SurveyStillLive = ? AND CPI >= ?", @usercountry, 400, true, @currentpayout).order( "SurveyGrossRank" ).each do |survey|


      if @foundtopsurveyswithquota == false then  #3 false means not finished finding top surveys
        

        if ( ((survey.CountryLanguageID == 5) &&        
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
          
          
          
          ((survey.CountryLanguageID == 6) &&          
#          ( survey.SurveyStillLive ) && 
          (( survey.QualificationAgePreCodes.empty? ) || ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([ user.age ] & survey.QualificationAgePreCodes.flatten) == [ user.age ] )) && 
          (( survey.QualificationGenderPreCodes.empty? ) || ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || ((@GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )) && 
          (( survey.QualificationZIPPreCodes.empty? ) || ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP.slice(0..2) ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP.slice(0..2) ])) &&
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
       
          
          
          ( (user.netid != "FmsuA567rw21345f54rrLLswaxzAHnms") &&
          (survey.CountryLanguageID == 9) &&          
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
          ) ||
          
                    
          
          ( (user.netid == "FmsuA567rw21345f54rrLLswaxzAHnms") &&
          (survey.CountryLanguageID == 9) &&          
#          ( survey.SurveyStillLive ) && 
          (survey.SurveyMobileConversion > 2) &&
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
          

          puts "---------------------------------->>>  FED Replace QualificationHHCPrecodes with CA_provincePrecodes column"
        
          print '************ FED User QUALIFIED for survey number = ', survey.SurveyNumber, ' RANK= ', survey.SurveyGrossRank, ' User enetered Gender: ', @GenderPreCode, ' Gender from Survey= ', survey.QualificationGenderPreCodes, ' USER ENTERED AGE= ', user.age, ' AGE PreCodes from Survey= ', survey.QualificationAgePreCodes, ' User Entered ZIP: ', user.ZIP, ' ZIP PreCodes from Survey: ..... ', ' User Entered Race: ', user.race, ' Race PreCode from survey: ', survey.QualificationRacePreCodes, ' User Entered ethnicity: ', user.ethnicity, ' Ethnicity PreCode from survey: ', survey.QualificationEthnicityPreCodes, ' User Entered education: ', user.eduation, ' Education PreCode from survey: ', survey.QualificationEducationPreCodes, ' User Entered HHI: ', user.householdincome, ' HHI PreCode from survey: ', survey.QualificationHHIPreCodes, ' User Entered Employment: ', user.employment, ' Std_Employment PreCode from survey: ', survey.QualificationEmploymentPreCodes, ' User Entered PIndustry: ', user.pindustry, ' PIndustry PreCode from survey: ', survey.QualificationPIndustryPreCodes, ' User Entered JobTitle: ', user.jobtitle, ' JobTitle PreCode from survey: ', survey.QualificationJobTitlePreCodes, ' User Entered Children: ', user.children, ' Children PreCodes from survey: ', survey.QualificationChildrenPreCodes, ' User Entered Industries: ', user.industries, ' Industries PreCodes from survey: ....', ' Network Payout: ', @currentpayout, ' CPI from survey: ', survey.CPI, ' SurveyStillAlive: ', survey.SurveyStillLive
         
        puts
        
        print '************* FED Gender match: ', @_gender, ' Age match: ', @_age, ' Age_logic value: ', @_age_value, ' Race match: ', @_race, ' Ethnicity match: ', @_ethnicity, ' Education match: ', @_education, ' HHI match: ', @_HHI, ' Employment match: ', @_employment, ' PIndustry match: ', @_pindustry, ' JobTitle match: ', @_jobtitle, ' Children match: ', @_children, ' Children_logic value: ', @_children_logic,  ' Industries match: ', @_industries, ' Industries_logic value: ', @_industries_logic, ' CPI check: ', @_CPI_check
        puts
        

        if (survey.CountryLanguageID == 9) then
          @_ZIP = ( survey.QualificationZIPPreCodes.empty? ) || ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
          @_DMA = (( survey.QualificationDMAPreCodes.empty? ) || ( survey.QualificationDMAPreCodes.flatten == [ "ALL" ] ) || (([ @DMARegionCode ] & survey.QualificationDMAPreCodes.flatten) == [ @DMARegionCode ]))
          @_State = (( survey.QualificationStatePreCodes.empty? ) || ( survey.QualificationStatePreCodes.flatten == [ "ALL" ] ) || (([ @statePrecode ] & survey.QualificationStatePreCodes.flatten) == [ @statePrecode ]))
          @_region = (( survey.QualificationRegionPreCodes.empty? ) || ( survey.QualificationRegionPreCodes.flatten == [ "ALL" ] ) || (([ @regionPrecode ] & survey.QualificationRegionPreCodes.flatten) == [ @regionPrecode ]))
          @_Division = (( survey.QualificationDivisionPreCodes.empty? ) || ( survey.QualificationDivisionPreCodes.flatten == [ "ALL" ] ) || (([ @divisionPrecode ] & survey.QualificationDivisionPreCodes.flatten) == [ @divisionPrecode ]))        
          
          
          
          # print '*********** FED User Entered ZIP: ', user.ZIP, ' ZIP PreCodes from Survey: ', survey.QualificationZIPPreCodes, 'DMA from DB: ', @DMARegionCode, ' DMA from Survey: ', survey.QualificationDMAPreCodes, 'Region from DB: ', @regionPrecode, ' Region from Survey: ', survey.QualificationRegionPreCodes, 'Division from DB: ', @divisionPrecode, ' Division from Survey: ', survey.QualificationDivisionPreCodes
          # puts          
          
          print '************** FED ZIP match: ', @_ZIP, ' DMA match: ', @_DMA, ' State match: ', @_State, ' Region match: ', @_region, ' Division match: ', @_Division
          puts
        else
        end
        
        if (survey.CountryLanguageID == 6) then
          @_ZIP = ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP.slice(0..2) ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP.slice(0..2) ])
          @_province_check = (( survey.QualificationHHCPreCodes.empty? ) || ( survey.QualificationHHCPreCodes.flatten == [ "ALL" ] ) || (([ @provincePrecode ] & survey.QualificationHHCPreCodes.flatten) == [ @provincePrecode ]))
          
          print '************** FED ZIP slice match: ', @_ZIP, 'CA Province match: ', @_province_check
          puts
        else
        end
        
        

        user.QualifiedSurveys << survey.SurveyNumber
        
        print '********** FED This USER_ID: ', user.user_id, ' has QUALIFIED for the following survey : ', survey.SurveyNumber
        puts
        
        print '********** FED In total This USER_ID: ', user.user_id, ' has QUALIFIED for the following surveys: ', user.QualifiedSurveys
        puts
              

          # Lets save the surveys user qualifies for in this user's record of database in rank order
          user.save
          
# redundant?

          # Look through the survey this user is qualified for, to check if there is quota available. Quota numbers can be read as Maximum or upper limit allowed for a qualification e.g. ages 20-24 quota of 30 and ages 25-30 quota of 50 is the upper limit on both of the groups. The code should first find if the number of respondents in the quota teh respondent falls in has need for more respondents. When a quota is split into parts then respondent must fall into at least one of them.
      
      
          puts "********************* FED STARTING To SEARCH if QUOTA is available for this user in the FED surveys user is Qualified. Stop after specified number of top ranked surveys with quota are found"
      
      
            @surveynumber = survey.SurveyNumber


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
              # if survey.SurveyQuotas[0]["NumberOfRespondents"] > 0 then #4
              if ((survey.SurveyQuotas[0]["NumberOfRespondents"] > 0) && ((survey.SurveyQuotas[0]["QuotaCPI"] == nil) || (survey.SurveyQuotas[0]["QuotaCPI"] > @currentpayout))) then #4
                                
                # print 'Total quota numberofrespondents is: ', survey.SurveyQuotas[0]["NumberOfRespondents"]
                # puts
                totalquotaexists = true
              else #4
                # Total NumberOfRespondent needed = 0 or Quota CPI < payout. No completes required
                print '*****k=0******** No completes required - no quota available for this syurvey or QuotaCPI < payout. QuotaCPI= ', survey.SurveyQuotas[0]["QuotaCPI"]
                puts
              end #4
            else #3
              # Lets assume that quota is open for all users so add this survey number to user's ride
              print '************* No Total quota ID found. Assuming that quota is open for ALL users. Might want to change this to refuse this survey based on experience. This should typically NOT happen.'
              puts

              
                           
              if (user.SurveysWithMatchingQuota.length == 0) then
                user.SurveysWithMatchingQuota << @surveynumber
              else
                @inserted = false
                (0..user.SurveysWithMatchingQuota.length-1).each do |i|
                  @survey1 = Survey.where('SurveyNumber = ?', user.SurveysWithMatchingQuota[i]).first
                  # @surveynumber is for survey
                  if ((survey.BidIncidence > @survey1.BidIncidence) && (@inserted == false)) then
                    user.SurveysWithMatchingQuota.insert(i, @surveynumber)
                    @inserted = true
                  else
                    if ( (i==user.SurveysWithMatchingQuota.length-1) && (@inserted == false) ) then
                      user.SurveysWithMatchingQuota << @surveynumber
                      @inserted = true
                    else
                    end
                  end
                end
              end              

              
                      
              if (user.country == '9') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_US) then
            
                @foundtopsurveyswithquota = true
          
              else
            
                if (user.country == '6') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_CA) then
              
                  @foundtopsurveyswithquota = true
            
                else
            
                  #if (user.country == '5') && (user.SurveysWithMatchingQuota.uniq.length >= @p2s_AU) then
                  if (user.country == '5') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_AU) then
                
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
                # print '***************** Starting at the next value of k i.e. next QuotaID: ', survey.SurveyQuotas[k]["SurveyQuotaID"]
                # puts
                @NumberOfRespondents = survey.SurveyQuotas[k]["NumberOfRespondents"]
                print 'Number of respondents =, in this quota ID index k=: ', @NumberOfRespondents, ' ', k
                puts
                # print '***** Questions in this quota: ', survey.SurveyQuotas[k]["Questions"]
                # puts

            
              if ((survey.SurveyQuotas[k]["NumberOfRespondents"] > 0) && ((survey.SurveyQuotas[k]["QuotaCPI"] == nil) || (survey.SurveyQuotas[k]["QuotaCPI"] > @currentpayout))) then #7
                            
                print '****************** Needs respondents for quota k=', k
                puts
            
                @NumberOfQuestions = survey.SurveyQuotas[k]["Questions"].length
            
                print '*********************** Number of questions = ', @NumberOfQuestions
                puts
            
                if @NumberOfQuestions == 1 then #8 unnested quota
 
    #              (0..survey.SurveyQuotas[k]["Questions"].length-1).each do |l| #10
                
                    l = 0
                    puts '**************** Number of questions is 1. Setting l=0'
                    # print '*********** Question ID= for the question is: ', survey.SurveyQuotas[k]["Questions"][l]["QuestionID"]
                    # puts
              
                  # check if a quota exists for this user by matching precodes for the questions (at l=0) in a quota (k)
            
              
                  case survey.SurveyQuotas[k]["Questions"][l]["QuestionID"] #9
                
                    when 42
                      # print 'Age: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
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
                      # print 'Gender: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
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

                      if ((user.country == '6') && ( [ user.ZIP.slice(0..2) ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ZIP.slice(0..2) ] )) ||
                        ((user.country == '5') && ( [ user.ZIP ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ZIP ] )) || 
                        ((user.country == '9') && ( [ user.ZIP ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ZIP ] )) then
                        
                        @ZIPquotaexists=true
                       puts '********** ZIP question matches'
                      else
                        @ZIPquotaexists=false || @ZIPquotaexists
                        puts '********** ZIP question does not match'
                      end
                  
                    when 47
                      # print 'Ethnicity (47, Hispanic): ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
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
                      # print 'Race (113, Ethnicity): ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
                      @racequotavalidationwasdone=true
                  
                      if ([ user.race ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.race ] ) then
                        racequotaexists = true
                        puts '*********** Race question matches'
                      else
                        racequotaexists = false || racequotaexists
                        puts '*********** Race question does not match'
                      end
                  
                  
                    when 633
                      # print 'Education: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
                      @educationquotavalidationwasdone=true
                  
                      if ([ user.eduation ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.eduation ] ) then
                        educationquotaexists = true
                        puts '*********** Education question matches'
                      else
                        educationquotaexists = false || educationquotaexists
                        puts '*********** Education question does not match'
                      end
                  
                    when 14785
                      # print 'Std_HHI_US: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
                      @hhiquotavalidationwasdone=true
                  
                      if ([ user.householdincome ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.householdincome ] ) then
                        hhiquotaexists = true
                        puts '*********** Std_HHI_US question matches'
                      else
                        hhiquotaexists = false || hhiquotaexists
                        puts '*********** Std_HHI_US question does not match'
                      end
                  
                    when 14887
                      # print 'Std_HHI_INT: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
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
                    # print '*********** Question ID = for this l (above) position in this nested quota is: ', survey.SurveyQuotas[k]["Questions"][l]["QuestionID"]
                    # puts

                  # check if a quota exists for this user by matching precodes for all questions (l) in a quota (k)
              
                  case survey.SurveyQuotas[k]["Questions"][l]["QuestionID"] #12
                
                    when 42
                      # print 'Age: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
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
                      # print 'Gender: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
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
                        
                      if ((user.country == '6') && ( [ user.ZIP.slice(0..2) ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ZIP.slice(0..2) ] )) ||
                        ((user.country == '5') && ( [ user.ZIP ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ZIP ] )) || 
                        ((user.country == '9') && ( [ user.ZIP ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ZIP ] )) then
                        
                        @nestedzipquotaexists=true
                       puts '********** nested ZIP question matches'
                      else
                        @nestedzipquotaexists=false
                        puts '********** nested ZIP question does not match'
                      end
                  
                    when 47
                      # print 'Ethnicity (47, Hispanic): ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
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
                      # print 'Race (113, Ethnicity): ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
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
                      # print 'Education: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
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
                      # print 'Std_HHI_US: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
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
                      # print 'Std_HHI_INT: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                      # puts
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
              
                else #7 NumbeOfRespondents for this Quota ID is <= 0 or QuotaCPI < payout
                  # No need to review questions for match
                  print '*****k>0******** No completes required - no quota available for this syurvey or QuotaCPI < payout. QuotaCPI= ', survey.SurveyQuotas[k]["QuotaCPI"]
                  puts
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
                puts '****************** Adding the survey to the list of eligible surveys due to quota availability'
                



                if (user.SurveysWithMatchingQuota.length == 0) then
                  user.SurveysWithMatchingQuota << @surveynumber
                else
                  @inserted = false
                  (0..user.SurveysWithMatchingQuota.length-1).each do |i|
                    survey1 = Survey.where('SurveyNumber = ?', user.SurveysWithMatchingQuota[i]).first
                    # @surveynumber is for survey
                    if ((survey.BidIncidence > survey1.BidIncidence) && (@inserted == false)) then
                      user.SurveysWithMatchingQuota.insert(i, @surveynumber)
                      @inserted = true
                    else
                      if ( (i==user.SurveysWithMatchingQuota.length-1) && (@inserted == false) ) then
                        user.SurveysWithMatchingQuota << @surveynumber
                        @inserted = true
                      else
                      end
                    end
                  end
                end
            


            
                if (user.country == '9') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_US) then
            
                  @foundtopsurveyswithquota = true
          
                else
            
                  if (user.country == '6') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_CA) then
              
                    @foundtopsurveyswithquota = true
            
                  else
            
                    #if (user.country == '5') && (user.SurveysWithMatchingQuota.uniq.length >= @p2s_AU) then
                    if (user.country == '5') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_AU) then
                
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
                puts '************* Adding survey in order of IR to list of eligible quotas even though no quotas specified but Totalquotaexists.'


                if (user.SurveysWithMatchingQuota.length == 0) then
                  user.SurveysWithMatchingQuota << @surveynumber
                else
                  # print "----------------->>>>>>>>>>>>> SurveysWithMatchingQuota: ", user.SurveysWithMatchingQuota
                  # puts
                  
                  @inserted = false
                  (0..user.SurveysWithMatchingQuota.length-1).each do |i|
                    s1 = Survey.where('SurveyNumber = ?', user.SurveysWithMatchingQuota[i]).first
                    
                    print "----------------->>>>>>>>>>>>> S1: ", s1.SurveyNumber
                    puts
                    
                    # @surveynumber is for survey
                    if ( ( survey.BidIncidence > s1.BidIncidence ) && (@inserted == false) ) then
                      user.SurveysWithMatchingQuota.insert(i, @surveynumber)
                      @inserted = true
                    else
                      if ( (i==user.SurveysWithMatchingQuota.length-1) && (@inserted == false) ) then
                        user.SurveysWithMatchingQuota << @surveynumber
                        @inserted = true
                      else
                      end
                    end
                  end
                end
                    
            
                if (user.country == '9') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_US) then
            
                  @foundtopsurveyswithquota = true
          
                else
            
                  if (user.country == '6') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_CA) then
              
                    @foundtopsurveyswithquota = true
            
                  else
            
                    #if (user.country == '5') && (user.SurveysWithMatchingQuota.uniq.length >= @p2s_AU) then
                    if (user.country == '5') && (user.SurveysWithMatchingQuota.uniq.length >= @fed_AU) then
                
                      @foundtopsurveyswithquota = true
              
                    else
              
                      #do nothing
              
                    end
            
                  end
          
                end
            
              end  # 6
            end #5 if there is quota specified in k = 0 (total) or more (other IDs)
        
        
      else
        # This survey qualifications did not match with the user
        # Print for testing/verification
        
        @_gender = ( survey.QualificationGenderPreCodes.empty? ) || ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (( @GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )
        @_age = ( survey.QualificationAgePreCodes.empty? ) || ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([user.age] & survey.QualificationAgePreCodes.flatten) == [user.age])
        @_age_value = [user.age] & survey.QualificationAgePreCodes.flatten
        @_race = (( survey.QualificationRacePreCodes.empty? ) || ( survey.QualificationRacePreCodes.flatten == [ "ALL" ] ) || (([ user.race ] & survey.QualificationRacePreCodes.flatten) == [ user.race ]))
        @_ethnicity = (( survey.QualificationEthnicityPreCodes.empty? ) || ( survey.QualificationEthnicityPreCodes.flatten == [ "ALL" ] ) || (([ user.ethnicity ] & survey.QualificationEthnicityPreCodes.flatten) == [ user.ethnicity ]))
        @_education = (( survey.QualificationEducationPreCodes.empty? ) || ( survey.QualificationEducationPreCodes.flatten == [ "ALL" ] ) || (([ user.eduation ] & survey.QualificationEducationPreCodes.flatten) == [ user.eduation ]))
        @_HHI= (( survey.QualificationHHIPreCodes.empty? ) || ( survey.QualificationHHIPreCodes.flatten == [ "ALL" ] ) || (([ user.householdincome ] & survey.QualificationHHIPreCodes.flatten) == [ user.householdincome ]))
        @_employment = (( survey.QualificationEmploymentPreCodes.empty? ) || ( survey.QualificationEmploymentPreCodes.flatten == [ "ALL" ] ) || (([ user.employment ] & survey.QualificationEmploymentPreCodes.flatten) == [ user.employment ]))
        @_pindustry = (( survey.QualificationPIndustryPreCodes.empty? ) || ( survey.QualificationPIndustryPreCodes.flatten == [ "ALL" ] ) || (([ user.pindustry ] & survey.QualificationPIndustryPreCodes.flatten) == [ user.pindustry ]))        
        @_jobtitle = (( survey.QualificationJobTitlePreCodes.empty? ) || ( survey.QualificationJobTitlePreCodes.flatten == [ "ALL" ] ) || (([ user.jobtitle ] & survey.QualificationJobTitlePreCodes.flatten) == [ user.jobtitle ]))
        @_children = (( survey.QualificationChildrenPreCodes.empty? ) || ( survey.QualificationChildrenPreCodes.flatten == [ "ALL" ] ) || (( user.children  & survey.QualificationChildrenPreCodes.flatten).empty? == false)) 
        @_children_logic = user.children & survey.QualificationChildrenPreCodes.flatten  
      #  @_industries = (( survey.QualificationIndustriesPreCodes.empty? ) || ( survey.QualificationIndustriesPreCodes.flatten == [ "ALL" ] ) || (( user.industries & survey.QualificationIndustriesPreCodes.flatten).empty? == false))
       # @_industries_logic = ( user.industries & survey.QualificationIndustriesPreCodes)
        @_CPI_check = ((survey.CPI == nil) || (survey.CPI >= @currentpayout))
        
        
        print '************ User DID NOT QUALIFY for survey number = ', survey.SurveyNumber, ' RANK= ', survey.SurveyGrossRank, ' User enetered Gender: ', @GenderPreCode, ' Gender from Survey= ', survey.QualificationGenderPreCodes, ' USER ENTERED AGE= ', user.age, ' AGE PreCodes from Survey= ', survey.QualificationAgePreCodes, ' User Entered ZIP: ', user.ZIP, ' ZIP PreCodes from Survey: ....... ', ' User Entered Race: ', user.race, ' Race PreCode from survey: ', survey.QualificationRacePreCodes, ' User Entered ethnicity: ', user.ethnicity, ' Ethnicity PreCode from survey: ', survey.QualificationEthnicityPreCodes, ' User Entered education: ', user.eduation, ' Education PreCode from survey: ', survey.QualificationEducationPreCodes, ' User Entered HHI: ', user.householdincome, ' HHI PreCode from survey: ', survey.QualificationHHIPreCodes, ' User Entered Employment: ', user.employment, ' Std_Employment PreCode from survey: ', survey.QualificationEmploymentPreCodes, ' User Entered PIndustry: ', user.pindustry, ' PIndustry PreCode from survey: ', survey.QualificationPIndustryPreCodes, ' User Entered JobTitle: ', user.jobtitle, ' JobTitle PreCode from survey: ', survey.QualificationJobTitlePreCodes, ' User Entered Children: ', user.children, ' Children PreCodes from survey: ', survey.QualificationChildrenPreCodes,  ' User Entered Industries: ', user.industries, ' Industries PreCodes from survey: ....', ' Network Payout: ', @currentpayout, ' CPI from survey: ', survey.CPI, ' SurveyStillAlive: ', survey.SurveyStillLive
         
        puts
        
        print '************** Gender match:', @_gender, ' Age match: ', @_age, ' Age_logic value: ', @_age_value, ' Race match: ', @_race, ' Ethnicity match: ', @_ethnicity, ' Education match: ', @_education, ' HHI match: ', @_HHI, ' Employment match: ', @_employment, ' PIndustry match: ', @_pindustry, ' JobTitle match: ', @_jobtitle, ' Children match: ', @_children, ' Children_logic value: ', @_children_logic,   ' Industries match: ', @_industries, ' Industries_logic value: ', @_industries_logic, ' CPI check: ', @_CPI_check
        puts
        
        if (survey.CountryLanguageID == 9) then
          @_ZIP = ( survey.QualificationZIPPreCodes.empty? ) || ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
          @_DMA = (( survey.QualificationDMAPreCodes.empty? ) || ( survey.QualificationDMAPreCodes.flatten == [ "ALL" ] ) || (([ @DMARegionCode ] & survey.QualificationDMAPreCodes.flatten) == [ @DMARegionCode ]))
          @_State = (( survey.QualificationStatePreCodes.empty? ) || ( survey.QualificationStatePreCodes.flatten == [ "ALL" ] ) || (([ @statePrecode ] & survey.QualificationStatePreCodes.flatten) == [ @statePrecode ]))
          @_region = (( survey.QualificationRegionPreCodes.empty? ) || ( survey.QualificationRegionPreCodes.flatten == [ "ALL" ] ) || (([ @regionPrecode ] & survey.QualificationRegionPreCodes.flatten) == [ @regionPrecode ]))
          @_Division = (( survey.QualificationDivisionPreCodes.empty? ) || ( survey.QualificationDivisionPreCodes.flatten == [ "ALL" ] ) || (([ @divisionPrecode ] & survey.QualificationDivisionPreCodes.flatten) == [ @divisionPrecode ]))
                    
          print '************** ZIP match: ', @_ZIP, ' DMA match: ', @_DMA, ' State match: ', @_State, ' Region match: ', @_region, ' Division match: ', @_Division
          puts
        else
        end
        
        
        if (survey.CountryLanguageID == 6) then
          @_ZIP = ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP.slice(0..2) ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP.slice(0..2) ])
          @_province_check = (( survey.QualificationHHCPreCodes.empty? ) || ( survey.QualificationHHCPreCodes.flatten == [ "ALL" ] ) || (([ @provincePrecode ] & survey.QualificationHHCPreCodes.flatten) == [ @provincePrecode ]))
          
          print '************** Sliced ZIP match: ', @_ZIP, ' CA Province match: ', @_province_check
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
    
    end # do loop for all surveys in Surveys db
        
    # Remove duplicate entries
      
    if (user.SurveysWithMatchingQuota.empty?) then
      p '--------------******************** RankFEDSurveys: No Surveys matching quota were found in Fulcrum ***************--------'

    else       
      user.SurveysWithMatchingQuota = user.SurveysWithMatchingQuota.uniq
      print '-----------------*************** List of Fulcrum surveys where quota is available *************************-----------:', user.SurveysWithMatchingQuota
      puts
    end
         
    # Get SupplierLinks for matched surveys

    (0..user.SurveysWithMatchingQuota.length-1).each do |i| #do14
      @surveynumber = user.SurveysWithMatchingQuota[i]
      Survey.where( "SurveyNumber = ?", @surveynumber ).each do |survey| # do15
        user.SupplierLink[i] = survey.SupplierLink["LiveLink"]
      end #do15
    end #do14
        
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
    
    if user.industries != nil then
      @industriesvalue = '&STANDARD_INDUSTRY='+user.industries[0]
      if user.industries.length > 1 then
        (1..user.industries.length-1).each do |i|
          @industriesvalue = @industriesvalue+'&STANDARD_INDUSTRY='+user.industries[i]
        end
      else
      end
    else
      @industriesvalue = ''
    end  
       
    if user.country=="9" then 
      @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&ZIP='+user.ZIP+'&HISPANIC='+user.ethnicity+'&ETHNICITY='+user.race+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_US='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.employment+'&STANDARD_INDUSTRY_PERSONAL='+user.pindustry+'&STANDARD_JOB_TITLE='+user.jobtitle+@childrenvalue+'&STATE='+@statePrecode+'&DMA='+@DMARegionCode+@industriesvalue
    else
      if user.country=="6" then
        @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&ZIP_Canada='+user.ZIP.slice(0..2)+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_INT='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.employment+'&STANDARD_INDUSTRY_PERSONAL='+user.pindustry+'&STANDARD_JOB_TITLE='+user.jobtitle+@childrenvalue+'&Province\/Territory_of_Canada='+@provincePrecode+@industriesvalue
      else
        if user.country=="5" then
          @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&Fulcrum_ZIP_AU='+user.ZIP+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_INT='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.employment+'&STANDARD_INDUSTRY_PERSONAL='+user.pindustry+'&STANDARD_JOB_TITLE='+user.jobtitle+@childrenvalue+@industriesvalue
        else
          if user.country=="7" then
            @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&Fulcrum_ZIP_IN='+user.ZIP+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_INT='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.employment+'&STANDARD_INDUSTRY_PERSONAL='+user.pindustry+'&STANDARD_JOB_TITLE='+user.jobtitle+@childrenvalue+@industriesvalue
          else
          end
        end
      end
    end    
        
    @parsed_user_agent = UserAgent.parse(user.user_agent)
    
    print "*************************************** RankFEDSurveys: User platform is: ", @parsed_user_agent.platform
    puts
    
    if (@parsed_user_agent.platform == 'iPhone') || (@parsed_user_agent.platform.include? "Android") then
      
      @MS_is_mobile = '&MS_is_mobile=true'
      p "*************************************** UserRide: MS_is_mobile is set TRUE"
      
    else
      @MS_is_mobile = '&MS_is_mobile=false'
      p "*************************************** UserRide: MS_is_mobile is set FALSE"
      
    end
    
    (0..user.SupplierLink.length-1).each do |i|
#      user.SupplierLink[i] = user.SupplierLink[i]+@PID+@AdditionalValues+@MS_is_mobile

      @BaseLink = user.SupplierLink[i]+@PID+@AdditionalValues+@MS_is_mobile+"&"

      # Add SHA-1 encryption to all links here

      @SHA1Signature = Base64.encode64((HMAC::SHA1.new(@SHA1key) << @BaseLink).digest).strip
  #    p 'Signature 1 =', @SHA1Signature  
      @SHA1Signature = @SHA1Signature.gsub '+', '-'
  #    p 'Signature 2 =', @SHA1Signature
      @SHA1Signature = @SHA1Signature.gsub '/', '_'
  #    p 'Signature 3 =', @SHA1Signature
      @SHA1Signature= @SHA1Signature.gsub '=', ''
  #    p 'Signature 4 =', @SHA1Signature

      user.SupplierLink[i] = @BaseLink+"ienc="+@SHA1Signature

    end   # do SupplierLink   
    
    # Save the FED survey numbers that the user meets the qualifications and quota requirements for in this user's record of database in rank order
    
    user.save

    @fedSupplierLinks = user.SupplierLink
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

#       if user.gender == '1' then
#         @GenderPreCode = [ "1" ]
#       else
#         @GenderPreCode = [ "2" ]
#       end    
    
#       if user.country == '6' then
# #      print "--------------------------->>>>>> First character of CA postalcode = ", user.ZIP.slice(0)
# #      puts
      
#         case user.ZIP.slice(0)
#         when "T"
#           @provincePrecode = "1"
# #         puts "Assigned Alberta @provincePrecode = 1"
        
#         when "V"
#           @provincePrecode = "2"
# #         puts "Assigned BC @provincePrecode = 2"
        
#         when "R"
#           @provincePrecode = "3"
# #         puts "Assigned MB @provincePrecode = 3"
        
#         when "E"
#           @provincePrecode = "4"
# #         puts "Assigned NB @provincePrecode = 4"
        
#         when "A"
#           @provincePrecode = "5"
# #         puts "Assigned NL @provincePrecode = 5"
        
#         when "X"
#           @provincePrecode = "6"
# #         puts "Assigned NT @provincePrecode = 6"
        
#         when "B"
#         @provincePrecode = "7"
# #        puts "Assigned NS @provincePrecode = 7"
        
#         # when "X"  # X would become a duplicate. Nunavut is teh least populated province so this is it
#         # @provincePrecode = "8"
#         # puts "Assigned NU @provincePrecode = 8"
        
#         when "K"
#           @provincePrecode = "9"
# #         puts "Assigned ON @provincePrecode = 9"
        
#         when "L"
#           @provincePrecode = "9"
# #         puts "Assigned ON @provincePrecode = 9"
        
#         when "M"
#           @provincePrecode = "9"
# #        puts "Assigned ON @provincePrecode = 9"
        
#         when "N"
#           @provincePrecode = "9"
# #        puts "Assigned ON @provincePrecode = 9"
        
#         when "P"
#           @provincePrecode = "9"
# #        puts "Assigned ON @provincePrecode = 9"

#         when "C"
#           @provincePrecode = "10"
# #        puts "Assigned PE @provincePrecode = 10"
        
#         when "G"
#           @provincePrecode = "11"
# #         puts "Assigned QC @provincePrecode = 11"
        
#         when "H"
#           @provincePrecode = "11"
# #         puts "Assigned QC @provincePrecode = 11"
        
#         when "J"
#           @provincePrecode = "11"
# #         puts "Assigned QC @provincePrecode = 11"
        
#         when "S"
#           @provincePrecode = "12"
# #         puts "Assigned SK @provincePrecode = 12"
        
#         when "Y"
#           @provincePrecode = "13"
# #         puts "Assigned YT @provincePrecode = 13"
#       end
#     else
#     end # country == 6
    
#     if @provincePrecode == nil then
#       # wild guess
#       @provincePrecode = "11"
#     else
#     end
           
#     if user.country == '9' then
#       @geo = UsGeo.find_by zip: user.ZIP
      
#       if @geo == nil then
#         @statePrecode = "0"
#         @DMARegionCode = "0"
#         @regionPrecode = "0"
#         @dividionPrecode = "0"
#         puts "NotApplicable PreCodes Used for INVALID ZIPCODE"
        
#       else
      
#         @DMARegionCode = @geo.DMARegionCode
#         @regionPrecode = @geo.regionPrecode
#         @divisionPrecode = @geo.divisionPrecode
        
#         case @geo.State
#         when "NotApplicable"
#           @statePrecode = "0"
#           print "NotApplicable PreCode Used for: ", @geo.State
#           puts
#         when "Alabama"
#           @statePrecode = "1"
#           print "Alabama PreCode Used for: ", @geo.State
#           puts
#         when "Alaska"
#           @statePrecode = "2"
#           print "Alaska PreCode Used for: ", @geo.State
#           puts
#         when "Arizona"
#           @statePrecode = "3"
#           print "Arizona PreCode Used for: ", @geo.State
#           puts
#         when "Arkansas"
#           @statePrecode = "4"
#           print "Arkansas PreCode Used for: ", @geo.State
#           puts
#         when "California"
#           @statePrecode = "5"
#           print "California PreCode Used for: ", @geo.State
#           puts
#         when "Colorado"
#           @statePrecode = "6"
#           print "Colorado PreCode Used for: ", @geo.State
#           puts
#         when "Connecticut"
#           @statePrecode = "7"
#           print "Connecticut PreCode Used for: ", @geo.State
#           puts
#         when "Delaware"
#           @statePrecode = "8"
#           print "Delaware PreCode Used for: ", @geo.State
#           puts
#         when "DistrictofColumbia"
#           @statePrecode = "9"
#           print "DistrictofColumbia PreCode Used for: ", @geo.State
#           puts
#         when "Florida"
#           @statePrecode = "10"
#           print "Florida PreCode Used for: ", @geo.State
#           puts
#         when "Georgia"
#           @statePrecode = "11"
#           print "Georgia PreCode Used for: ", @geo.State
#           puts
#         when "Hawaii"
#           @statePrecode = "12"
#           print "Hawaii PreCode Used for: ", @geo.State
#           puts
#         when "Idaho"
#           @statePrecode = "13"
#           print "Idaho PreCode Used for: ", @geo.State
#           puts
#         when "Illinois"
#           @statePrecode = "14"
#           print "Illinois PreCode Used for: ", @geo.State
#           puts
#         when "Indiana"
#           @statePrecode = "15"
#           print "Indiana PreCode Used for: ", @geo.State
#           puts
#         when "Iowa"
#           @statePrecode = "16"
#           print "Iowa PreCode Used for: ", @geo.State
#           puts
#         when "Kansas"
#           @statePrecode = "17"
#           print "Kansas PreCode Used for: ", @geo.State
#           puts
#         when "Kentucky"
#           @statePrecode = "18"
#           print "Kentucky PreCode Used for: ", @geo.State
#           puts
#         when "Louisiana"
#           @statePrecode = "19"
#           print "Louisiana PreCode Used for: ", @geo.State
#           puts
#         when "Maine"
#           @statePrecode = "20"
#           print "Maine PreCode Used for: ", @geo.State
#           puts
#         when "Maryland"
#           @statePrecode = "21"
#           print "Maryland PreCode Used for: ", @geo.State
#           puts
#         when "Massachusetts"
#           @statePrecode = "22"
#           print "Massachusetts PreCode Used for: ", @geo.State
#           puts
#         when "Michigan"
#           @statePrecode = "23"
#           print "Michigan PreCode Used for: ", @geo.State
#           puts
#         when "Minnesota"
#           @statePrecode = "24"
#           print "Minnesota PreCode Used for: ", @geo.State
#           puts
#         when "Mississippi"
#           @statePrecode = "25"
#           print "Mississippi PreCode Used for: ", @geo.State
#           puts
#         when "Missouri"
#           @statePrecode = "26"
#           print "Missouri PreCode Used for: ", @geo.State
#           puts
#         when "Montana"
#           @statePrecode = "27"
#           print "Montana PreCode Used for: ", @geo.State
#           puts
#         when "Nebraska"
#           @statePrecode = "28"
#           print "Nebraska PreCode Used for: ", @geo.State
#           puts
#         when "Nevada"
#           @statePrecode = "29"
#           print "Nevada PreCode Used for: ", @geo.State
#           puts
#         when "NewHampshire"
#           @statePrecode = "30"
#           print "NewHampshire PreCode Used for: ", @geo.State
#           puts
#         when "NewJersey"
#           @statePrecode = "31"
#           print "NewJersey PreCode Used for: ", @geo.State
#           puts
#         when "NewMexico"
#           @statePrecode = "32"
#           print "NewMexico PreCode Used for: ", @geo.State
#           puts
#         when "NewYork"
#           @statePrecode = "33"
#           print "NewYork PreCode Used for: ", @geo.State
#           puts
#         when "NorthCarolina"
#           @statePrecode = "34"
#           print "NorthCarolina PreCode Used for: ", @geo.State
#           puts
#         when "NorthDakota"
#           @statePrecode = "35"
#           print "NorthDakota PreCode Used for: ", @geo.State
#           puts
#         when "Ohio"
#           @statePrecode = "36"
#           print "Ohio PreCode Used for: ", @geo.State
#           puts
#         when "Oklahoma"
#           @statePrecode = "37"
#           print "Oklahoma PreCode Used for: ", @geo.State
#           puts
#         when "Oregon"
#           @statePrecode = "38"
#           print "Oregon PreCode Used for: ", @geo.State
#           puts
#         when "Pennsylvania"
#           @statePrecode = "39"
#           print "Pennsylvania PreCode Used for: ", @geo.State
#           puts
#         when "RhodeIsland"
#           @statePrecode = "40"
#           print "RhodeIsland PreCode Used for: ", @geo.State
#           puts
#         when "SouthCarolina"
#           @statePrecode = "41"
#           print "SouthCarolina PreCode Used for: ", @geo.State
#           puts
#         when "SouthDakota"
#           @statePrecode = "42"
#           print "SouthDakota PreCode Used for: ", @geo.State
#           puts
#         when "Tennessee"
#           @statePrecode = "43"
#           print "Tennessee PreCode Used for: ", @geo.State
#           puts
#         when "Texas"
#           @statePrecode = "44"
#           print "Texas PreCode Used for: ", @geo.State
#           puts
#         when "Utah"
#           @statePrecode = "45"
#           print "Utah PreCode Used for: ", @geo.State
#           puts
#         when "Vermont"
#           @statePrecode = "46"
#           print "Vermont PreCode Used for: ", @geo.State
#           puts
#         when "Virginia"
#           @statePrecode = "47"
#             print "Virginia PreCode Used for: ", @geo.State
#             puts
#         when "Washington"
#           @statePrecode = "48"
#           print "Washington PreCode Used for: ", @geo.State
#           puts
#         when "WestVirginia"
#           @statePrecode = "49"
#           print "WestVirginia PreCode Used for: ", @geo.State
#           puts
#         when "Wisconsin"
#           @statePrecode = "50"
#           print "Wisconsin PreCode Used for: ", @geo.State
#           puts
#         when "Wyoming"
#           @statePrecode = "51"
#           print "Wyoming PreCode Used for: ", @geo.State
#           puts
# #      when "NotApplicable"
# #        @statePrecode = "52"
# #        print "NotApplicable PreCode Used for: ", @geo.State
# #        puts
#         when "AmericanSamoa"
#           @statePrecode = "53"
#           print "AmericanSamoa PreCode Used for: ", @geo.State
#           puts
#         when "FederatedStatesofMicronesia"
#           @statePrecode = "54"
#           print "FederatedStatesofMicronesia PreCode Used for: ", @geo.State
#           puts
#         when "Guam"
#           @statePrecode = "55"
#           print "Guam PreCode Used for: ", @geo.State
#           puts
#         when "MarshallIslands"
#           @statePrecode = "56"
#           print "MarshallIslands PreCode Used for: ", @geo.State
#           puts
#         when "NorthernMarinaIslands"
#           @statePrecode = "57"
#           print "NorthernMarinaIslands PreCode Used for: ", @geo.State
#           puts
#         when "Palau"
#           @statePrecode = "58"
#           print "Palau PreCode Used for: ", @geo.State
#           puts
#         when "PuertoRico"
#           @statePrecode = "59"
#           print "PuertoRico PreCode Used for: ", @geo.State
#           puts
#         when "VirginIslands"
#           @statePrecode = "60"
#           print "VirginIslands PreCode Used for: ", @geo.State
#           puts
#         end # case
        
#       end # if @geo = nil
      
#     else
#     end # if country = 9


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
        p '****************************** minimum payout for ADHOC set to: ', @currentpayout
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


  
  def selectRfgProjects (session_id)
    
    require 'digest/hmac'
    require 'net/http'
    require 'uri'
    
    apid = "54ef65c3e4b04d0ae6f9f4a7"
    secret = "8ef1fe91d92e0602648d157f981bb934"
    
    user=User.find_by session_id: session_id
    
    @RFGclient = Network.find_by name: "RFG"
    if (@RFGclient.status == "ACTIVE") && (@RFGIsOff != true) then
      @rid = @RFGclient.netid+user.user_id
    
      print "**************** Assigned RFG @rid = ", @rid
      puts
     
#     if user.country == '9' then
#       @geo = UsGeo.find_by zip: user.ZIP
      
#       if @geo == nil then
#         @statePrecode = "0"
#         @DMARegionCode = "0"
#         @regionPrecode = "0"
#         @dividionPrecode = "0"
#         @rfgCountyChoice = 0
#         puts "NotApplicable PreCodes Used for INVALID ZIPCODE"
        
#       else
      
#         @DMARegionCode = @geo.DMARegionCode
#         @regionPrecode = @geo.regionPrecode
#         @divisionPrecode = @geo.divisionPrecode
#         @rfgCountyChoice = @geo.estimated_population
        
#         case @geo.State
#         when "NotApplicable"
#           @statePrecode = "0"
#           print "NotApplicable PreCode Used for: ", @geo.State
#           puts
#         when "Alabama"
#           @statePrecode = "1"
#           print "Alabama PreCode Used for: ", @geo.State
#           puts
#         when "Alaska"
#           @statePrecode = "2"
#           print "Alaska PreCode Used for: ", @geo.State
#           puts
#         when "Arizona"
#           @statePrecode = "3"
#           print "Arizona PreCode Used for: ", @geo.State
#           puts
#         when "Arkansas"
#           @statePrecode = "4"
#           print "Arkansas PreCode Used for: ", @geo.State
#           puts
#         when "California"
#           @statePrecode = "5"
#           print "California PreCode Used for: ", @geo.State
#           puts
#         when "Colorado"
#           @statePrecode = "6"
#           print "Colorado PreCode Used for: ", @geo.State
#           puts
#         when "Connecticut"
#           @statePrecode = "7"
#           print "Connecticut PreCode Used for: ", @geo.State
#           puts
#         when "Delaware"
#           @statePrecode = "8"
#           print "Delaware PreCode Used for: ", @geo.State
#           puts
#         when "DistrictofColumbia"
#           @statePrecode = "9"
#           print "DistrictofColumbia PreCode Used for: ", @geo.State
#           puts
#         when "Florida"
#           @statePrecode = "10"
#           print "Florida PreCode Used for: ", @geo.State
#           puts
#         when "Georgia"
#           @statePrecode = "11"
#           print "Georgia PreCode Used for: ", @geo.State
#           puts
#         when "Hawaii"
#           @statePrecode = "12"
#           print "Hawaii PreCode Used for: ", @geo.State
#           puts
#         when "Idaho"
#           @statePrecode = "13"
#           print "Idaho PreCode Used for: ", @geo.State
#           puts
#         when "Illinois"
#           @statePrecode = "14"
#           print "Illinois PreCode Used for: ", @geo.State
#           puts
#         when "Indiana"
#           @statePrecode = "15"
#           print "Indiana PreCode Used for: ", @geo.State
#           puts
#         when "Iowa"
#           @statePrecode = "16"
#           print "Iowa PreCode Used for: ", @geo.State
#           puts
#         when "Kansas"
#           @statePrecode = "17"
#           print "Kansas PreCode Used for: ", @geo.State
#           puts
#         when "Kentucky"
#           @statePrecode = "18"
#           print "Kentucky PreCode Used for: ", @geo.State
#           puts
#         when "Louisiana"
#           @statePrecode = "19"
#           print "Louisiana PreCode Used for: ", @geo.State
#           puts
#         when "Maine"
#           @statePrecode = "20"
#           print "Maine PreCode Used for: ", @geo.State
#           puts
#         when "Maryland"
#           @statePrecode = "21"
#           print "Maryland PreCode Used for: ", @geo.State
#           puts
#         when "Massachusetts"
#           @statePrecode = "22"
#           print "Massachusetts PreCode Used for: ", @geo.State
#           puts
#         when "Michigan"
#           @statePrecode = "23"
#           print "Michigan PreCode Used for: ", @geo.State
#           puts
#         when "Minnesota"
#           @statePrecode = "24"
#           print "Minnesota PreCode Used for: ", @geo.State
#           puts
#         when "Mississippi"
#           @statePrecode = "25"
#           print "Mississippi PreCode Used for: ", @geo.State
#           puts
#         when "Missouri"
#           @statePrecode = "26"
#           print "Missouri PreCode Used for: ", @geo.State
#           puts
#         when "Montana"
#           @statePrecode = "27"
#           print "Montana PreCode Used for: ", @geo.State
#           puts
#         when "Nebraska"
#           @statePrecode = "28"
#           print "Nebraska PreCode Used for: ", @geo.State
#           puts
#         when "Nevada"
#           @statePrecode = "29"
#           print "Nevada PreCode Used for: ", @geo.State
#           puts
#         when "NewHampshire"
#           @statePrecode = "30"
#           print "NewHampshire PreCode Used for: ", @geo.State
#           puts
#         when "NewJersey"
#           @statePrecode = "31"
#           print "NewJersey PreCode Used for: ", @geo.State
#           puts
#         when "NewMexico"
#           @statePrecode = "32"
#           print "NewMexico PreCode Used for: ", @geo.State
#           puts
#         when "NewYork"
#           @statePrecode = "33"
#           print "NewYork PreCode Used for: ", @geo.State
#           puts
#         when "NorthCarolina"
#           @statePrecode = "34"
#           print "NorthCarolina PreCode Used for: ", @geo.State
#           puts
#         when "NorthDakota"
#           @statePrecode = "35"
#           print "NorthDakota PreCode Used for: ", @geo.State
#           puts
#         when "Ohio"
#           @statePrecode = "36"
#           print "Ohio PreCode Used for: ", @geo.State
#           puts
#         when "Oklahoma"
#           @statePrecode = "37"
#           print "Oklahoma PreCode Used for: ", @geo.State
#           puts
#         when "Oregon"
#           @statePrecode = "38"
#           print "Oregon PreCode Used for: ", @geo.State
#           puts
#         when "Pennsylvania"
#           @statePrecode = "39"
#           print "Pennsylvania PreCode Used for: ", @geo.State
#           puts
#         when "RhodeIsland"
#           @statePrecode = "40"
#           print "RhodeIsland PreCode Used for: ", @geo.State
#           puts
#         when "SouthCarolina"
#           @statePrecode = "41"
#           print "SouthCarolina PreCode Used for: ", @geo.State
#           puts
#         when "SouthDakota"
#           @statePrecode = "42"
#           print "SouthDakota PreCode Used for: ", @geo.State
#           puts
#         when "Tennessee"
#           @statePrecode = "43"
#           print "Tennessee PreCode Used for: ", @geo.State
#           puts
#         when "Texas"
#           @statePrecode = "44"
#           print "Texas PreCode Used for: ", @geo.State
#           puts
#         when "Utah"
#           @statePrecode = "45"
#           print "Utah PreCode Used for: ", @geo.State
#           puts
#         when "Vermont"
#           @statePrecode = "46"
#           print "Vermont PreCode Used for: ", @geo.State
#           puts
#         when "Virginia"
#           @statePrecode = "47"
#             print "Virginia PreCode Used for: ", @geo.State
#             puts
#         when "Washington"
#           @statePrecode = "48"
#           print "Washington PreCode Used for: ", @geo.State
#           puts
#         when "WestVirginia"
#           @statePrecode = "49"
#           print "WestVirginia PreCode Used for: ", @geo.State
#           puts
#         when "Wisconsin"
#           @statePrecode = "50"
#           print "Wisconsin PreCode Used for: ", @geo.State
#           puts
#         when "Wyoming"
#           @statePrecode = "51"
#           print "Wyoming PreCode Used for: ", @geo.State
#           puts
# #      when "NotApplicable"
# #        @statePrecode = "52"
# #        print "NotApplicable PreCode Used for: ", @geo.State
# #        puts
#         when "AmericanSamoa"
#           @statePrecode = "53"
#           print "AmericanSamoa PreCode Used for: ", @geo.State
#           puts
#         when "FederatedStatesofMicronesia"
#           @statePrecode = "54"
#           print "FederatedStatesofMicronesia PreCode Used for: ", @geo.State
#           puts
#         when "Guam"
#           @statePrecode = "55"
#           print "Guam PreCode Used for: ", @geo.State
#           puts
#         when "MarshallIslands"
#           @statePrecode = "56"
#           print "MarshallIslands PreCode Used for: ", @geo.State
#           puts
#         when "NorthernMarinaIslands"
#           @statePrecode = "57"
#           print "NorthernMarinaIslands PreCode Used for: ", @geo.State
#           puts
#         when "Palau"
#           @statePrecode = "58"
#           print "Palau PreCode Used for: ", @geo.State
#           puts
#         when "PuertoRico"
#           @statePrecode = "59"
#           print "PuertoRico PreCode Used for: ", @geo.State
#           puts
#         when "VirginIslands"
#           @statePrecode = "60"
#           print "VirginIslands PreCode Used for: ", @geo.State
#           puts
#         end # case
        
#         print "------------------------>>>>>>>>>>>>>>>>>> User geo credentials in RFG are - Zip: ", user.ZIP, " DMA: ", @DMARegionCode, " Region: ", @regionPrecode, " Division: ", @divisionPrecode
#         puts
        
#       end # if @geo = nil
           
#     else
#     end # if country = 9    
         
    # if user.country == '9' then
    #   user_country = "US"
    # else
    #   if user.country == '6' then
    #     user_country = "CA"
    #   else
    #     if user.country == '5' then
    #       user_country = "AU"
    #     else
    #     end
    #   end
    # end
          
    # # Initialize for the number of RFG projects to be included
    
    # @foundtopprojectswithquota = false  
    # @netid = user.netid
      
    # if Network.where(netid: @netid).exists? then
    #   net = Network.find_by netid: @netid
  
    #   if net.payout == nil then
    #     @currentpayout = 1.25 # assumes $1.25 as minimum payout value across the networks for RFG projects
    #     @currentpayoutstr = "$"+@currentpayout.to_s
    #   else
    #     @currentpayout = net.payout # RFG CPI includes 10% extra payout 
    #     @currentpayoutstr = "$"+@currentpayout.to_s
    #     p '****************************** minimum payout for RFG set to: ', @currentpayout
    #     puts
    #   end
       
    #   if net.RFG_US != nil then
    #     if (net.RFG_US == 0) && (user.country == "9") then
    #       @foundtopprojectswithquota = true
    #       puts "**************** No US RFG project is included "
    #     else
    #       @RFG_US = net.RFG_US
    #     end
    #   else
    #     @RFG_US = 0
    #     @foundtopprojectswithquota = true
    #   end
      
    #   if net.RFG_CA != nil then
    #     if (net.RFG_CA == 0) && (user.country == "6") then
    #       @foundtopprojectswithquota = true
    #       puts "**************** No CA RFG project is included "
    #     else
    #       @RFG_CA = net.RFG_CA
    #     end        
    #   else
    #     @RFG_CA = 0
    #     @foundtopprojectswithquota = true
    #   end
      
    #   if net.RFG_AU != nil then
    #     if (net.RFG_AU == 0) && (user.country == "5") then
    #       @foundtopprojectswithquota = true
    #       puts "**************** No AU RFG project is included "
    #     else
    #       @RFG_AU = net.RFG_AU
    #     end        
    #   else
    #     @RFG_AU = 0
    #     @foundtopprojectswithquota = true
    #   end
      
    # else
    #   # Bad netid, Network is not known
    #   p '****************************** selectRFGProjects: ACCESS FROM AN UNRECOGNIZED NETWOK DENIED'
    #   redirect_to '/users/nosuccess'
    #   return
    # end
        
#     #Initialize an array to store qualified projects
#     @RFGQualifiedProjects = Array.new
#     @RFGProjectsWithQuota = Array.new
#     @RFGSupplierLinks = Array.new
    
    
#     if user.country == "9" then  
              
#     #RfgProject.where("country = ? AND state = ?", user_country, 2).order(epc: :desc).order(projectEPC: :desc).each do |project|
#     RfgProject.where("country = ? AND state = ?", user_country, 2).order(estimatedIR: :desc).order(projectEPC: :desc).each do |project|
#       if @foundtopprojectswithquota == false then  #3 false means not finished finding top projects     
        
#         if project.projectStillLive then
                
#         # Initialize qualification parameters to true. These are turned false if user does not qualify
#         @QualificationAge = true
#         @QualificationGender = true
#         @QualificationComputer = true
#         @QualificationZip = true
#         @QualificationHhi = true
#         @QualificationPindustry = true
#         @QualificationChildren = true
#         @QualificationEducation = true
#         @QualificationEmployment = true
#         @QualificationCounty = true
#         @QualificationDMA = true
#         @QualificationState = true
#         @QualificationRegion = true        
#         @QualificationJobTitle = true
#         @QualificationEthnicity = true
     
        
#         (0..project.datapoints.length-1).each do |m|
        
#           case project.datapoints[m]["name"]
#           when "Age"
#             # logic: once found true then set to true
#             @QualificationAge = false
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#               @QualificationAge = (project.datapoints[m]["values"][i]["min"]..project.datapoints[m]["values"][i]["max"]).include?(user.age.to_i) || @QualificationAge
#             end
#             # print "User entered age: ", user.age
#             # puts
#             # print "Project qual age: ", project.datapoints[m]["values"]
#             # puts
#             print "@QualificationAge: ", @QualificationAge
#             puts
            
#           when "Gender"
#             if project.datapoints[m]["values"].length == 2 then
#               @QualificationGender = true
#             else
#               if project.datapoints[m]["values"][0]["choice"] == user.gender.to_i then
#                 @QualificationGender = true
#               else
#                 @QualificationGender = false
#               end
#             end
#             # print "User entered gender: ", user.gender
#             # puts
#             # print "Project qual gender: ", project.datapoints[m]["values"]
#             # puts
#             print "@QualificationGender: ", @QualificationGender
#             puts
            
            
#           when "Computer Check"
#             @QualificationComputer = false
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#              if ((((project.datapoints[m]["values"][i]["choice"] == 1) || (project.datapoints[m]["values"][i]["choice"] == 2) || (project.datapoints[m]["values"][i]["choice"] == 4) || (project.datapoints[m]["values"][i]["choice"] == 5)) && (@MS_is_mobile == '&MS_is_mobile=false')) || (((project.datapoints[m]["values"][i]["choice"] == 3)) && (@MS_is_mobile == '&MS_is_mobile=true'))) then 
#                @QualificationComputer = true
#              else
#              end
#             end
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>User computer type: ", @MS_is_mobile
#             puts
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Project qualified computer types: ", project.datapoints[m]["values"]
#             puts
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>@QualificationComputer: ", @QualificationComputer
#             puts
            
#           when "List of Zips"
#             @QualificationZip = false
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#              if (project.datapoints[m]["values"][i]["freelist"]).include?(user.ZIP) then 
#                @QualificationZip = true
#              else
#              end
#             end
#             # print "User entered zip: ", user.ZIP
#             # puts
#             # print "Project qual zip: ", project.datapoints[m]["values"]
#             # puts
#             print "@QualificationZip: ", @QualificationZip
#             puts
            
#           when "Household Income"
#             @QualificationHhi = false
#             @RFGHhi = ''
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#               if (project.datapoints[m]["values"][i]["choice"] == 1) && ( (user.householdincome.to_i == 1) || (user.householdincome.to_i == 2) || (user.householdincome.to_i == 3) || (user.householdincome.to_i == 27) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 2) && ( (user.householdincome.to_i == 4) || (user.householdincome.to_i == 5) || (user.householdincome.to_i == 27) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 3) && ( (user.householdincome.to_i == 6) || (user.householdincome.to_i == 7) || (user.householdincome.to_i == 8) || (user.householdincome.to_i == 9) || (user.householdincome.to_i == 10) || (user.householdincome.to_i == 27) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 4) && ( (user.householdincome.to_i == 11) || (user.householdincome.to_i == 12) || (user.householdincome.to_i == 13) || (user.householdincome.to_i == 14) || (user.householdincome.to_i == 15) || (user.householdincome.to_i == 27) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 5) && ( (user.householdincome.to_i == 16) || (user.householdincome.to_i == 17) || (user.householdincome.to_i == 18) || (user.householdincome.to_i == 19) || (user.householdincome.to_i == 20) || (user.householdincome.to_i == 27) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 6) && ( (user.householdincome.to_i == 21) || (user.householdincome.to_i == 22) || (user.householdincome.to_i == 27) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 7) && ( (user.householdincome.to_i == 23) || (user.householdincome.to_i == 24) || (user.householdincome.to_i == 27) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 8) && ( (user.householdincome.to_i == 25) || (user.householdincome.to_i == 26) || (user.householdincome.to_i == 27) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if ( (project.datapoints[m]["values"][i]["choice"] == 9) || (project.datapoints[m]["values"][i]["choice"] == 10) || (project.datapoints[m]["values"][i]["choice"] == 11) ) && ( (user.householdincome.to_i == 26) || (user.householdincome.to_i == 27) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               print "===========================$$$$$$$$$$$$$$$$$$$$$$$============@RFGHhi===============: ", @RFGHhi
#               puts

#             end
#             # print "User entered HHI: ", user.householdincome
#             # puts
#             # print "Project qual HHI: ", project.datapoints[m]["values"]
#             # puts
#             print "@QualificationHhi: ", @QualificationHhi
#             puts
            
#             # when "STANDARD_HHI_INT"
#             # @QualificationHhi = false
#             # (0..project.datapoints[m]["values"].length-1).each do |i|
#               # if project.datapoints[m]["values"][i]["choice"] == user.householdincome.to_i then
#                 # @QualificationHhi = true
#                 # else
#                 # end
#             # end
#             # print "User entered HHI: ", user.householdincome
#             # puts
#             # print "Project qual HHI: ", project.datapoints[m]["values"]
#             # puts
#             # print "@QualificationHhi: ", @QualificationHhi
#             # puts
              
#           when "Employment Industry"
#             @QualificationPindustry = false
#             @RFGPindustry = ''
      
#             (0..project.datapoints[m]["values"].length-1).each do |i|

#               if (project.datapoints[m]["values"][i]["choice"] == 1) && (user.pindustry.to_i == 1) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 2) && (user.pindustry.to_i == 2) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 3) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 4) && (user.pindustry.to_i == 3) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 5) && (user.pindustry.to_i == 4) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 6) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 7) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 8) && (user.pindustry.to_i == 5) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 9) && (user.pindustry.to_i == 6) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 10) && (user.pindustry.to_i == 7) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 11) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 12) && (user.pindustry.to_i == 8) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 13) && (user.pindustry.to_i == 9) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 14) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 15) && (user.pindustry.to_i == 10) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 16) && (user.pindustry.to_i == 11) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 17) && (user.pindustry.to_i == 12) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 18) && (user.pindustry.to_i == 13) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 19) && (user.pindustry.to_i == 14) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 20) && (user.pindustry.to_i == 15) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 21) && (user.pindustry.to_i == 16) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 22) && (user.pindustry.to_i == 17) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 23) && (user.pindustry.to_i == 18) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 24) && (user.pindustry.to_i == 19) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 25) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 26) && (user.pindustry.to_i == 20) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 27) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 28) && (user.pindustry.to_i == 22) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 29) && (user.pindustry.to_i == 23) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 30) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 31) && (user.pindustry.to_i == 24) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 32) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 33) && (user.pindustry.to_i == 25) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 34) && (user.pindustry.to_i == 26) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 35) && (user.pindustry.to_i == 27) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 36) && (user.pindustry.to_i == 28) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 37) && (user.pindustry.to_i == 29) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 38) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 39) && (user.pindustry.to_i == 30) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 40) && (user.pindustry.to_i == 31) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 41) && (user.pindustry.to_i == 32) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 42) && (user.pindustry.to_i == 33) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 43) && (user.pindustry.to_i == 34) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 44) && (user.pindustry.to_i == 35) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 45) && (user.pindustry.to_i == 36) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 46) && (user.pindustry.to_i == 37) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 47) && (user.pindustry.to_i == 38) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 48) && (user.pindustry.to_i == 39) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 49) && (user.pindustry.to_i == 40) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 50) && (user.pindustry.to_i == 41) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 51) && (user.pindustry.to_i == 42) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 52) && (user.pindustry.to_i == 44) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 53) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 54) && (user.pindustry.to_i == 45) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 55) && (user.pindustry.to_i == 46) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 56) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 57) && (user.pindustry.to_i == 49) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 58) && (user.pindustry.to_i == 48) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 59) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 60) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 61) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 62) && ( (user.pindustry.to_i == 50) || (user.pindustry.to_i == 21) || (user.pindustry.to_i == 43) || (user.pindustry.to_i == 47) ) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 63) && (user.pindustry.to_i == 51) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
 
#             end
#             print "User entered Pindustry: ", user.pindustry
#             puts
#             print "Project qual Pindustry: ", project.datapoints[m]["values"]
#             puts
#             print "@QualificationPindustry: ", @QualificationPindustry
#             puts                  
          
#           when "Children"
#             @QualificationChildren = false
#             y=1
#             if user.children.include?("-3105") then
#               @QualificationChildren = false
#             else
#               (0..user.children.length-1).each do |c|
#                 (0..project.datapoints[m]["values"].length-1).each do |i|
#                   if (project.datapoints[m]["values"][i]["unit"]!=nil) then
#                     if (project.datapoints[m]["values"][i]["unit"]==0) then 
#                       y=1
#                     else
#                       y=12
#                     end
#                   else
#                     y=1
#                   end
#                   @QualificationChildren = (((project.datapoints[m]["values"][i]["min"]..project.datapoints[m]["values"][i]["max"]).include?(((user.children[c].to_f/2).round)*y)) && ((project.datapoints[m]["values"][i]["gender"] == nil) || (user.children[c].to_i % 2==project.datapoints[m]["values"][i]["gender"].to_i % 2))) || @QualificationChildren
#                 end
#               end
#             end
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> User entered Children: ", user.children
#             puts
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Project qual Children: ", project.datapoints[m]["values"]
#             puts
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> @QualificationChildren: ", @QualificationChildren
#             puts    
          
          
#           # when "Children Age and Gender"
# #               @QualificationChildren = false
# #               (0..project.datapoints[m]["values"].length-1).each do |i|
# #                 if ((project.datapoints[m]["values"][i]["choice"].to_s & user.children).empty? == false) then
# #                   @QualificationChildren = true
# #                 else
# #                 end
# #               end
#               # print "User entered Children: ", user.children
#               # puts
#               # print "Project qual Children: ", project.datapoints[m]["values"]
#               # puts
#               # print "@QualificationChildren: ", @QualificationChildren
# #               puts
                
#           when "Education (US)"
#               @QualificationEducation = false
#               @RFGEducationUS = ''
              
#               (0..project.datapoints[m]["values"].length-1).each do |i|
#                 if (project.datapoints[m]["values"][i]["choice"] <= 7) && ((project.datapoints[m]["values"][i]["choice"] == user.eduation.to_i)) then
#                   @QualificationEducation = true
#                   @RFGEducationUS = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end                  
#                 if (project.datapoints[m]["values"][i]["choice"] == 7) && ((user.eduation.to_i == 8) || (user.eduation.to_i == 9) || (user.eduation.to_i == 10)) then
#                   @QualificationEducation = true
#                   @RFGEducationUS = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 8) && (user.eduation.to_i == 11) then
#                   @QualificationEducation = true
#                   @RFGEducationUS = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 9) && (user.eduation.to_i == 12) then
#                   @QualificationEducation = true
#                   @RFGEducationUS = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end                    
#               end
#               # print "User entered Education: ", user.eduation
#               # puts
#               # print "Project qual Education: ", project.datapoints[m]["values"]
#               # puts
#               print "@QualificationEducation: ", @QualificationEducation
#               puts
                  
#             when "Job Title"
#                 @QualificationJobTitle = false
#                 @RFGJobTitle = ''
                    
#                 (0..project.datapoints[m]["values"].length-1).each do |i|
                                      
#                       if (project.datapoints[m]["values"][i]["choice"] == 2) && (user.jobtitle.to_i == 1) then
#                         @QualificationJobTitle = true
#                         @RFGJobTitle = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                       if (project.datapoints[m]["values"][i]["choice"] == 3) && ((user.jobtitle.to_i == 2) || (user.jobtitle.to_i == 3)) then
#                         @QualificationJobTitle = true
#                         @RFGJobTitle = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                       if (project.datapoints[m]["values"][i]["choice"] == 4) && (user.jobtitle.to_i == 4) then
#                         @QualificationJobTitle = true
#                         @RFGJobTitle = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end  
#                       if (project.datapoints[m]["values"][i]["choice"] > 4) then
#                         @QualificationJobTitle = true
#                         @RFGJobTitle = ''
#                       else
#                       end
                                       
#                     end
#                 # print "User entered JobTitle: ", user.jobtitle
#                 # puts
#                 # print "Project qual JobTitle: ", project.datapoints[m]["values"]
#                 # puts
#                 print "@QualificationJobTitle: ", @QualificationJobTitle
#                 puts
                    
                    
              
#             when "Ethnicity (US)"
#               @QualificationEthnicity = false
#               @RFGEthnicity = ''
              
#               (0..project.datapoints[m]["values"].length-1).each do |i|
                
#                 # Remember in in FED and when reading user input we treat ethnicity input '113' as 'user.race'              
#                 if (project.datapoints[m]["values"][i]["choice"] == 1) && (user.race.to_i == 2) then
#                   @QualificationEthnicity = true
#                   @RFGEthnicity = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 2) && ( (user.race.to_i == 4) || (user.race.to_i == 5) || (user.race.to_i == 6) || (user.race.to_i == 7) || (user.race.to_i == 8) || (user.race.to_i == 9) || (user.race.to_i == 10) ) then
#                   @QualificationEthnicity = true
#                   @RFGEthnicity = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 3) && (user.race.to_i == 1) then
#                   @QualificationEthnicity = true
#                   @RFGEthnicity = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 4) && ( (user.race.to_i == 11) || (user.race.to_i == 12) || (user.race.to_i == 13) || (user.race.to_i == 14) ) then
#                   @QualificationEthnicity = true
#                   @RFGEthnicity = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 # RFG 5 is for Latino - same as ethnicity in FED
#                 if (project.datapoints[m]["values"][i]["choice"] == 5) && ( (user.ethnicity.to_i == 2) || (user.ethnicity.to_i == 3) || (user.ethnicity.to_i == 4) || (user.ethnicity.to_i == 5) || (user.ethnicity.to_i == 6) || (user.ethnicity.to_i == 7) || (user.ethnicity.to_i == 8) || (user.ethnicity.to_i == 9) || (user.ethnicity.to_i == 10) || (user.ethnicity.to_i == 11) || (user.ethnicity.to_i == 12) || (user.ethnicity.to_i == 13) || (user.ethnicity.to_i == 14) ) then
#                   @QualificationEthnicity = true
#                   @RFGEthnicity = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 6) && (user.race.to_i == 3) then
#                   @QualificationEthnicity = true
#                   @RFGEthnicity = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 7) && (user.race.to_i == 16) then
#                   @QualificationEthnicity = true
#                   @RFGEthnicity = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
                
#               end
#               # print "User entered Ethnicity: ", user.race
#               # puts
#               # print "Project qual Ethnicity: ", project.datapoints[m]["values"]
#               # puts
#               print "@QualificationEthnicity: ", @QualificationEthnicity
#               puts
#               print "@RFGEthnicity is set to: ", @RFGEthnicity
#               puts
                
                        
#             when "Employment Status"
#               @QualificationEmployment = false
#               @RFGEmployment = ''
              
#               (0..project.datapoints[m]["values"].length-1).each do |i|
#               if (project.datapoints[m]["values"][i]["choice"] == 1) && (user.employment.to_i == 10) then
#                 @QualificationEmployment = true
#                 @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end 
#                       if (project.datapoints[m]["values"][i]["choice"] == 2) && (user.employment.to_i == 2) then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                       if (project.datapoints[m]["values"][i]["choice"] == 3) && (user.employment.to_i == 1) then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                       if (project.datapoints[m]["values"][i]["choice"] == 4) && (user.employment.to_i == 7)  then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                       if (project.datapoints[m]["values"][i]["choice"] == 5) && (user.employment.to_i == 9)  then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                       if (project.datapoints[m]["values"][i]["choice"] == 6) && ((user.employment.to_i == 3) || (user.employment.to_i == 4)) then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end                    
#                       if (project.datapoints[m]["values"][i]["choice"] == 7) && (user.employment.to_i == 8)  then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                     end
#           # print "User entered Employment: ", user.employment
#           # puts
#           # print "Project qual Employment: ", project.datapoints[m]["values"]
#           # puts
#           print "@QualificationEmployment: ", @QualificationEmployment
#           puts
          
#         when "County (US)"
#           @QualificationCounty = false
#           (0..project.datapoints[m]["values"].length-1).each do |i|
#             if project.datapoints[m]["values"][i]["choice"] == @rfgCountyChoice then
#               @QualificationCounty = true
#             else
#             end
#           end
#           print "--------------------------------->>>>>>>>> County for user zipcode: ", @rfgCountyChoice
#           puts
#           print "--------------------------------->>>>>>>>> Project qual County: ", project.datapoints[m]["values"]
#           puts
#           print "@QualificationCounty: ", @QualificationCounty
#           puts
          
#         when "DMA (US)"
#           @QualificationDMA = false
#           (0..project.datapoints[m]["values"].length-1).each do |i|
#             if project.datapoints[m]["values"][i]["choice"] == @DMARegionCode.to_i then
#               @QualificationDMA = true
#             else
#             end
#           end
#           # print "User entered DMA: ", @DMARegionCode
#           # puts
#           # print "Project qual DMA: ", project.datapoints[m]["values"]
#           # puts
#           print "@QualificationDMA: ", @QualificationDMA
#           puts         
                    
#         when "State (US)"
#           @QualificationState = false
#           (0..project.datapoints[m]["values"].length-1).each do |i|
#             if project.datapoints[m]["values"][i]["choice"] == @statePrecode.to_i then
#               @QualificationState = true
#             else
#             end
#           end
#           # print "User entered State: ", @statePrecode
#           # puts
#           # print "Project qual State: ", project.datapoints[m]["values"]
#           # puts
#           print "@QualificationState: ", @QualificationState
#           puts
          
#         when "Region (US)"
#           @QualificationRegion = false
#           (0..project.datapoints[m]["values"].length-1).each do |i|
#             if project.datapoints[m]["values"][i]["choice"] == @regionPrecode.to_i then
#               @QualificationRegion = true
#             else
#             end
#           end
#           # print "User entered Region: ", @regionPrecode
#           # puts
#           # print "Project qual Region: ", project.datapoints[m]["values"]
#           # puts
#           print "@QualificationRegion: ", @QualificationRegion
#           puts          
          
          
#         end # case statement
#         end # do m
        
        
#         print " QUALIFICATIONS CRITERIA for: ", project.rfg_id
#         puts
#         print "country = ", (project.country == "US")
#         puts
#         print "cpi = ", (project.cpi > @currentpayoutstr)
#         puts        
#         print "Live = ", (project.projectStillLive)
#         puts
#         print "Age = ", (@QualificationAge)
#         puts
#         print "Gender = ", (@QualificationGender)
#         puts
#         print "Computer = ", (@QualificationComputer)
#         puts
#         print "Zip = ", (@QualificationZip)
#         puts
#         print "HHI = ", (@QualificationHhi)
#         puts
#         print "PIndustry = ", (@QualificationPindustry)
#         puts
#         print "Education = ", (@QualificationEducation)
#         puts
#         print "Employment = ", (@QualificationEmployment)
#         puts
#         print "JobTitle = ", (@QualificationJobTitle)
#         puts
#         print "Ethnicity = ", (@QualificationEthnicity)
#         puts
#         print "Children = ", (@QualificationChildren)
#         puts
#         print "County = ", (@QualificationCounty)
#         puts
#         print "DMA = ", (@QualificationDMA)
#         puts
#         print "State = ", (@QualificationState)
#         puts
#         print "Region = ", (@QualificationRegion)
#         puts
#         print "MobileOptimized = ", (project.mobileOptimized == "confirmed")
#         puts
        
         
#         if ( ( (project.country == "US") && (user.netid != "FmsuA567rw21345f54rrLLswaxzAHnms") && ( project.projectStillLive ) && (project.cpi > @currentpayoutstr) && ( @QualificationAge ) && ( @QualificationGender ) && (@QualificationComputer) && ( @QualificationZip ) && ( @QualificationHhi ) && ( @QualificationPindustry ) && ( @QualificationEducation ) && ( @QualificationEmployment ) && (@QualificationChildren) && (@QualificationCounty) && (@QualificationDMA) && (@QualificationState) && (@QualificationRegion) && (@QualificationJobTitle) && (@QualificationEthnicity) ) || 
#            ( (project.country == "US") && (user.netid == "FmsuA567rw21345f54rrLLswaxzAHnms") && (project.mobileOptimized == "confirmed") && ( project.projectStillLive ) && (project.cpi > @currentpayoutstr) && ( @QualificationAge ) && ( @QualificationGender ) && (@QualificationComputer) && ( @QualificationZip ) && ( @QualificationHhi ) && ( @QualificationPindustry ) && ( @QualificationEducation ) && ( @QualificationEmployment ) && (@QualificationChildren) && (@QualificationCounty) && (@QualificationDMA) && (@QualificationState) && (@QualificationRegion) && (@QualificationJobTitle) && (@QualificationEthnicity) ) )
          
#           then
          
#           @RFGQualifiedProjects << project.rfg_id
          
#           print '********** In total USER_ID: ', user.user_id, ' has QUALIFIED for the following RFG projects: ', @RFGQualifiedProjects
#           puts
          

#           # Verify if there is a quota for the qualified user and if it is full
          
#           if project.quotas.length > 0 then
#             # @RFGQuotaIsAvailable = false # initialize quota availability as false, then check quotas to prove/disprove
#            # @RFGQuotaFull = false
           
#             print "--------------------------------------------------------------->>>>>>>>> NUMBER OF QUOTAS = ", project.quotas.length
#             puts
            
#             (0..project.quotas.length-1).each do |j|
#               (0..project.quotas[j]["datapoints"].length-1).each do |n|
            
#               # Assume quota per qualifications is available. These are turned false if user does not qualify
#               @QualificationAge = true
#               @QualificationGender = true
#               @QualificationComputer = true
#               @QualificationZip = true
#               @QualificationHhi = true
#               @QualificationPindustry = true
#               @QualificationChildren = true
#               @QualificationEducation = true
#               @QualificationEmployment = true
#               @QualificationCounty = true
#               @QualificationDMA = true
#               @QualificationState = true
#               @QualificationRegion = true
              
                                        
#               case project.quotas[j]["datapoints"][n]["name"]
#               when "Age"
#                 #logic: once found true then turn to true
#                 @QualificationAge = false
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                   @QualificationAge = (project.quotas[j]["datapoints"][n]["values"][i]["min"]..project.quotas[j]["datapoints"][n]["values"][i]["max"]).include?(user.age.to_i) || @QualificationAge
#                 end
#                 # print "User entered age: ", user.age
#                 # puts
#                 # print "Project quota age: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 print "Quota for @QualificationAge: ", @QualificationAge
#                 puts
            
#               when "Gender"
#                 if project.quotas[j]["datapoints"][n]["values"].length == 2 then
#                   @QualificationGender = true
#                 else
#                   if project.quotas[j]["datapoints"][n]["values"][0]["choice"] == user.gender.to_i then
#                     @QualificationGender = true
#                   else
#                     @QualificationGender = false
#                   end
#                 end
#                 # print "User entered gender: ", user.gender
#                 # puts
#                 # print "Project quota gender: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 print "Quota for @QualificationGender: ", @QualificationGender
#                 puts
                
#               when "Computer Check"
#                 @QualificationComputer = false
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                  if ((((project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5)) && (@MS_is_mobile == '&MS_is_mobile=false')) || (((project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3)) && (@MS_is_mobile == '&MS_is_mobile=true'))) then 
#                    @QualificationComputer = true
#                  else
#                  end
#                 end
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>User computer type: ", @MS_is_mobile
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Project quota for computer types: ", project.quotas[j]["datapoints"][n]["values"]
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>@QualificationComputer: ", @QualificationComputer
#                 puts
                
            
#               when "List of Zips"
#                 @QualificationZip = false
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                  if (project.quotas[j]["datapoints"][n]["values"][i]["freelist"]).include?(user.ZIP) then 
#                    @QualificationZip = true
#                  else
#                  end
#                 end
#                 # print "User entered zip: ", user.ZIP
#                 # puts
#                 # print "Project quota zip: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 print "Quota for @QualificationZip: ", @QualificationZip
#                 puts
            
#               when "Household Income"
#                 @QualificationHhi = false
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                     
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && ( (user.householdincome.to_i == 1) || (user.householdincome.to_i == 2) || (user.householdincome.to_i == 3) || (user.householdincome.to_i == 27) ) then
#                     @QualificationHhi = true
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && ( (user.householdincome.to_i == 4) || (user.householdincome.to_i == 5) || (user.householdincome.to_i == 27) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && ( (user.householdincome.to_i == 6) || (user.householdincome.to_i == 7) || (user.householdincome.to_i == 8) || (user.householdincome.to_i == 9) || (user.householdincome.to_i == 10) || (user.householdincome.to_i == 27) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && ( (user.householdincome.to_i == 11) || (user.householdincome.to_i == 12) || (user.householdincome.to_i == 13) || (user.householdincome.to_i == 14) || (user.householdincome.to_i == 15) || (user.householdincome.to_i == 27) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && ( (user.householdincome.to_i == 16) || (user.householdincome.to_i == 17) || (user.householdincome.to_i == 18) || (user.householdincome.to_i == 19) || (user.householdincome.to_i == 20) || (user.householdincome.to_i == 27) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && ( (user.householdincome.to_i == 21) || (user.householdincome.to_i == 22) || (user.householdincome.to_i == 27) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && ( (user.householdincome.to_i == 23) || (user.householdincome.to_i == 24) || (user.householdincome.to_i == 27) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 8) && ( (user.householdincome.to_i == 4) || (user.householdincome.to_i == 25) || (user.householdincome.to_i == 27) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if ( (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 9) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 10) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 11) ) && ( (user.householdincome.to_i == 26) || (user.householdincome.to_i == 27) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
#                 end
#                 # print "User entered HHI: ", user.householdincome
#                 # puts
#                 # print "Project HHI quota: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 print "Quota for @QualificationHhi: ", @QualificationHhi
#                 puts
            
#               when "Employment Industry"
#                 @QualificationPindustry = false
    
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|

#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && (user.pindustry.to_i == 1) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && (user.pindustry.to_i == 2) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && (user.pindustry.to_i == 3) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && (user.pindustry.to_i == 4) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 8) && (user.pindustry.to_i == 5) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 9) && (user.pindustry.to_i == 6) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 10) && (user.pindustry.to_i == 7) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 11) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 12) && (user.pindustry.to_i == 8) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 13) && (user.pindustry.to_i == 9) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 14) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 15) && (user.pindustry.to_i == 10) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 16) && (user.pindustry.to_i == 11) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 17) && (user.pindustry.to_i == 12) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 18) && (user.pindustry.to_i == 13) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 19) && (user.pindustry.to_i == 14) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 20) && (user.pindustry.to_i == 15) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 21) && (user.pindustry.to_i == 16) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 22) && (user.pindustry.to_i == 17) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 23) && (user.pindustry.to_i == 18) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 24) && (user.pindustry.to_i == 19) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 25) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 26) && (user.pindustry.to_i == 20) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 27) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 28) && (user.pindustry.to_i == 22) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 29) && (user.pindustry.to_i == 23) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 30) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 31) && (user.pindustry.to_i == 24) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 32) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 33) && (user.pindustry.to_i == 25) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 34) && (user.pindustry.to_i == 26) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 35) && (user.pindustry.to_i == 27) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 36) && (user.pindustry.to_i == 28) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 37) && (user.pindustry.to_i == 29) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 38) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 39) && (user.pindustry.to_i == 30) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 40) && (user.pindustry.to_i == 31) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 41) && (user.pindustry.to_i == 32) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 42) && (user.pindustry.to_i == 33) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 43) && (user.pindustry.to_i == 34) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 44) && (user.pindustry.to_i == 35) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 45) && (user.pindustry.to_i == 36) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 46) && (user.pindustry.to_i == 37) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 47) && (user.pindustry.to_i == 38) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 48) && (user.pindustry.to_i == 39) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 49) && (user.pindustry.to_i == 40) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 50) && (user.pindustry.to_i == 41) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 51) && (user.pindustry.to_i == 42) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 52) && (user.pindustry.to_i == 44) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 53) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 54) && (user.pindustry.to_i == 45) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 55) && (user.pindustry.to_i == 46) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 56) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 57) && (user.pindustry.to_i == 49) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 58) && (user.pindustry.to_i == 48) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 59) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 60) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 61) && (user.pindustry.to_i == 50) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 62) && ( (user.pindustry.to_i == 50) || (user.pindustry.to_i == 21) || (user.pindustry.to_i == 43) || (user.pindustry.to_i == 47) ) then
#                     @QualificationPindustry = true
#                   else
#                   end
            
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 63) && (user.pindustry.to_i == 51) then
#                     @QualificationPindustry = true
#                   else
#                   end                  
#                 end
#                 # print "User entered Pindustry: ", user.pindustry
#                 # puts
#                 # print "Project quota Pindustry: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 print "Quota for @QualificationPindustry: ", @QualificationPindustry
#                 puts
                  
#               when "Children"
#                 @QualificationChildren = false
#                 y=1
#                 if user.children.include?("-3105") then
#                   @QualificationChildren = false
#                 else
#                   (0..user.children.length-1).each do |c|
#                     (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                       if (project.quotas[j]["datapoints"][n]["values"][i]["unit"]!=nil) then
#                         if (project.quotas[j]["datapoints"][n]["values"][i]["unit"]==0) then 
#                           y=1
#                         else
#                           y=12
#                         end
#                       else
#                         y=1
#                       end
#                       @QualificationChildren = (((project.quotas[j]["datapoints"][n]["values"][i]["min"]..project.quotas[j]["datapoints"][n]["values"][i]["max"]).include?(((user.children[c].to_f/2).round)*y)) && ((project.quotas[j]["datapoints"][n]["values"][i]["gender"] == nil) || (user.children[c].to_i % 2==project.quotas[j]["datapoints"][n]["values"][i]["gender"].to_i % 2))) || @QualificationChildren
#                     end
#                   end
#                 end
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> User entered Children: ", user.children
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Project quota Children: ", project.quotas[j]["datapoints"][n]["values"]
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Quota for @QualificationChildren: ", @QualificationChildren
#                 puts    
              
              
#               # when "Children Age and Gender"
# #                   @QualificationChildren = false
# #                   (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
# #                     if ((project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s & user.children).empty? == false) then
# #                       @QualificationChildren = true
# #                     else
# #                     end
# #                   end
# #                   # print "User entered Children: ", user.children
# #                   # puts
# #                   # print "Project quota Children: ", project.quotas[j]["datapoints"][n]["values"]
# #                   # puts
# #                   print "@QualificationChildren: ", @QualificationChildren
# #                   puts
                
#               when "Education (US)"
#                   @QualificationEducation = false
#                   (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] <= 7) && ((project.quotas[j]["datapoints"][n]["values"][i]["choice"] == user.eduation.to_i)) then
#                       @QualificationEducation = true
#                       @RFGEducationUS = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                     else
#                     end                  
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && ((user.eduation.to_i == 8) || (user.eduation.to_i == 9) || (user.eduation.to_i == 10)) then
#                       @QualificationEducation = true
#                       @RFGEducationUS = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                     else
#                     end
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 8) && (user.eduation.to_i == 11) then
#                       @QualificationEducation = true
#                       @RFGEducationUS = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                     else
#                     end
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 9) && (user.eduation.to_i == 12) then
#                       @QualificationEducation = true
#                       @RFGEducationUS = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                     else
#                     end                    
#                   end
#                   # print "User entered Education: ", user.eduation
#                   # puts
#                   # print "Project quota Education: ", project.quotas[j]["datapoints"][n]["values"]
#                   # puts
#                   print "Quota for @QualificationEducation: ", @QualificationEducation
#                   puts
                        
#                 when "Employment Status"
#                   @QualificationEmployment = false
#                   (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && (user.employment.to_i == 10) then
#                     @QualificationEmployment = true
#                     @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end 
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && (user.employment.to_i == 2) then
#                             @QualificationEmployment = true
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && (user.employment.to_i == 1) then
#                             @QualificationEmployment = true
#                             print "----------->>> project employment choice: ", project.quotas[j]["datapoints"][n]["values"][i]["choice"], 'and user.employment: ', user.employment
#                             puts 
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && (user.employment.to_i == 7)  then
#                             @QualificationEmployment = true
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && (user.employment.to_i == 9)  then
#                             @QualificationEmployment = true
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && ((user.employment.to_i == 3) || (user.employment.to_i == 4)) then
#                             @QualificationEmployment = true
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end                    
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && (user.employment.to_i == 8)  then
#                             @QualificationEmployment = true
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end
#                         end
#               # print "User entered Employment: ", user.employment
#               # puts
#               # print "Project quota Employment: ", project.quotas[j]["datapoints"][n]["values"]
#               # puts
#               print "Quota for @QualificationEmployment: ", @QualificationEmployment
#               puts
          
#             when "County (US)"
#               @QualificationCounty = false
#               (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                 if project.quotas[j]["datapoints"][n]["values"][i]["choice"] == @rfgCountyChoice then
#                   @QualificationCounty = true
#                 else
#                 end
#               end
#               print "--------------------------------->>>>>>>>> County for user zipcode quota: ", @rfgCountyChoice
#               puts
#               print "--------------------------------->>>>>>>>> Project quota County: ", project.quotas[j]["datapoints"][n]["values"]
#               puts
#               print "Quota for @QualificationCounty: ", @QualificationCounty
#               puts
            
#             when "DMA (US)"
#               @QualificationDMA = false
#               (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                 if project.quotas[j]["datapoints"][n]["values"][i]["choice"] == @DMARegionCode.to_i then
#                   @QualificationDMA = true
#                 else
#                 end
#               end
#               # print "User entered DMA: ", @DMARegionCode
#               # puts
#               # print "Project quota DMA: ", project.quotas[j]["datapoints"][n]["values"]
#               # puts
#               print "Quota for @QualificationDMA: ", @QualificationDMA
#               puts
                    
#             when "State (US)"
#               @QualificationState = false
#               (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                 if project.quotas[j]["datapoints"][n]["values"][i]["choice"] == @statePrecode.to_i then
#                   @QualificationState = true
#                 else
#                 end
#               end
#               # print "User entered State: ", @statePrecode
#               # puts
#               # print "Project quota State: ", project.quotas[j]["datapoints"][n]["values"]
#               # puts
#               print "Quota for @QualificationState: ", @QualificationState
#               puts
          
#             when "Region (US)"
#               @QualificationRegion = false
#               (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                 if project.quotas[j]["datapoints"][n]["values"][i]["choice"] == @regionPrecode.to_i then
#                   @QualificationRegion = true
#                 else
#                 end
#               end
#               # print "User entered Region: ", @regionPrecode
#               # puts
#               # print "Project quota Region: ", project.quotas[j]["datapoints"][n]["values"]
#               # puts
#               print "Quota for @QualificationRegion: ", @QualificationRegion
#               puts          
              
#               end # case statement
              
#               if project.quotas[j]["datapoints"][n]["completesLeft"] == nil then
#                 @QuotaCompletesLeft = true
#                 p "************* RFG CompletesLeft is UNDEFINED ***************"
#               else 
#                 if (project.quotas[j]["datapoints"][n]["completesLeft"] > 0) then
#                   @QuotaCompletesLeft = true
#                   p "************* RFG CompletesLeft is > 0  ***************"

#                 else
#                   @QuotaCompletesLeft = false
#                   p "************* RFG CompletesLeft is = 0  ***************"
#                 end
#               end
              
#               print " QUOTA AVAILABILITY CRITERIA for: ", project.rfg_id
#               puts
#               print "country = ", (project.country == "US")
#               puts
#               print "Age = ", (@QualificationAge)
#               puts
#               print "Gender = ", (@QualificationGender)
#               puts
#               print "Computer = ", (@QualificationComputer)
#               puts
#               print "Zip = ", (@QualificationZip)
#               puts
#               print "HHI = ", (@QualificationHhi)
#               puts
#               print "PIndustry = ", (@QualificationPindustry)
#               puts
#               print "Education = ", (@QualificationEducation)
#               puts
#               print "Employment = ", (@QualificationEmployment)
#               puts
#               print "Children = ", (@QualificationChildren)
#               puts
#               print "County = ", (@QualificationCounty)
#               puts
#               print "DMA = ", (@QualificationDMA)
#               puts
#               print "State = ", (@QualificationState)
#               puts
#               print "Region = ", (@QualificationRegion)
#               puts
#               print "CompletesLeft = ", (@QuotaCompletesLeft)
#               puts          
              
#               if ( (project.country == "US") && ( @QualificationAge ) && ( @QualificationGender ) && (@QualificationComputer) && ( @QualificationZip ) && ( @QualificationHhi ) && ( @QualificationPindustry )  && ( @QualificationEducation ) && ( @QualificationEmployment ) && (@QualificationEducation) && (@QualificationChildren) && (@QualificationCounty) && (@QualificationDMA) && (@QualificationState) && (@QualificationRegion) && (@QuotaCompletesLeft) ) then
              
#                 @RFGQuotaIsAvailable = true
#                 puts "******* Quota is available"
#               else
#                 # if previous quota was available then preserve that fact
#                 @RFGQuotaIsAvailable = false || @RFGQuotaIsAvailable
#               end
              
              
#               end # reviewed all n nested qualifications of a quota
                           
#             end # all j quotas have been inspected

#           else
            
#             print "************** Quota available: There are no quota restrictions"
#             puts
            
#             @RFGQuotaIsAvailable = true
#           end
                   
#           if @RFGQuotaIsAvailable == true then
          
#             print '********** USER_ID: ', user.user_id, ' has Quota for the RFG project: ', project.rfg_id
#             puts
           
#             print "--------------*************** Checking for duplicate user fingerprint for project number: ", project.rfg_id
#             puts
                  
#             # lets assume the user is not a duplicate, typically
#             @duplicateFingerprint = false
        
#             if user.fingerprint != nil then
        
#               print "--------------->>>>>>******************* user fingerprint: ", user.fingerprint
#               puts
        
#               command = { :command => "livealert/duplicateCheck/1", :rfg_id => project.rfg_id, :fingerprint => user.fingerprint, :ip => user.ip_address }.to_json
                    
#               time=Time.now.to_i
#               hash = Digest::HMAC.hexdigest("#{time}#{command}", secret.scan(/../).map {|x| x.to_i(16).chr}.join, Digest::SHA1)
#               uri = URI("https://www.saysoforgood.com/API?apid=#{apid}&time=#{time}&hash=#{hash}")
            
#               begin
#                 Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
#                   req = Net::HTTP::Post.new uri
#                   req.body = command
#                   req.content_type = 'application/json'
#                   response = http.request req
#                   @RFGFingerprint = JSON.parse(response.body)  
#                 end
                    
#                 rescue Net::ReadTimeout => e  
#                 puts e.message
#               end
              
#               print "******************* Fingerprint 1, result: ", @RFGFingerprint, ' ', @RFGFingerprint["result"]
#               puts
                      
#               if ((@RFGFingerprint == nil) || (@RFGFingerprint["result"] != 0))  then
#                 @duplicateFingerprint = true            
#                 puts "----------->>>>>> @RFGFingerprint response returned by rfg server was not valid. User will not be allowed to enter, ZZZZZZZZ"
            
#               else
                        
#                 print "******************* Fingerprint 2, isDuplicate?: ", @RFGFingerprint, ' ', @RFGFingerprint["response"]["isDuplicate"]
#                 puts
                      
#                 if @RFGFingerprint["response"]["isDuplicate"] == true then
#                   @duplicateFingerprint = true
#                   puts "----------->>>>>> @RFGFingerprint response returned by rfg server was true. User will not be allowed to enter, XXXXXXXX"             
#                 else
#                   @duplicateFingerprint = false
#                   puts "----------->>>>>> @RFGFingerprint response returned by rfg server was false, User can enter VVVVVVVVVV"
#                 end
              
#               end      
                 
#             else
#               # Force it to be not duplicate because it had no fingerprint
#               @duplicateFingerprint = false          
#               puts "----------->>>>>> user fingerprint was nil. User can enter, CCCCCCCCC"
          
#             end # fingerprint == nil
            
#             if  @duplicateFingerprint == false then
                 
#               print "*************** This is not a duplicate user for this project. Add to list of projects for userride ", project.rfg_id
#               puts
            
            
#               if (@RFGProjectsWithQuota.length == 0) then
#                 @RFGProjectsWithQuota << project.rfg_id
#                 @RFGSupplierLinks << project.link+'&rfg_id='+project.rfg_id
#               else
#                 @inserted = false
#                 (0..@RFGProjectsWithQuota.length-1).each do |i|
#                   project1 = RfgProject.where('rfg_id = ?', @RFGProjectsWithQuota[i]).first
#                   if ( (project.estimatedIR > project1.estimatedIR) && (@inserted == false) ) then
#                     @RFGProjectsWithQuota.insert(i, project.rfg_id)
#                     @RFGSupplierLinks.insert(i, project.link+'&rfg_id='+project.rfg_id)
#                     @inserted = true
#                   else
#                   end
#                 end
#                 if (@inserted == false) then
#                   # insert it at the end since this new rfg_id project has the lowest IR
#                   @RFGProjectsWithQuota << project.rfg_id
#                   @RFGSupplierLinks << project.link+'&rfg_id='+project.rfg_id
#                 else
#                 end                  
#               end
                
            
#               if (user.country == '9') && (@RFGProjectsWithQuota.uniq.length >= @RFG_US) then
          
#                 @foundtopprojectswithquota = true
        
#               else
          
#                 if (user.country == '6') && (@RFGProjectsWithQuota.uniq.length >= @RFG_CA) then
            
#                   @foundtopprojectswithquota = true
          
#                 else
          
#                   #do nothing
          
#                 end
        
#               end              
              
#             else
            
#               print '-------------->>> DUPLICATE: Skip this project as User has already completed this project', project.rfg_id
#               puts
          
#             end # if @duplicateFingerprint
            
#           else
            
#             print '********** USER_ID: ', user.user_id, ' DOES NOT HAVE ANY Quota available for the RFG projects: ', project.rfg_id
#             puts
#           end # if quota available = true
          
#         else
          
#           print '************ User DID NOT QUALIFY for project number = ', project.rfg_id
#           puts
          
#         end # Qualification check
 
#         else
#         end # if projectStillLive
 
#       else
#       end # if foundtopprojects
      
#     end # do all projects
    
#     else
#     end # country == 9
       
#     if user.country == "6" then  
              
#     #RfgProject.where("country = ? AND state = ?", user_country, 2).order(epc: :desc).order(projectEPC: :desc).each do |project|
#     RfgProject.where("country = ? AND state = ?", user_country, 2).order(estimatedIR: :desc).order(projectEPC: :desc).each do |project|

#       if @foundtopprojectswithquota == false then  #3 false means not finished finding top projects     
        
#         if project.projectStillLive then
                
#         # Initialize qualification parameters to true. These are turned false if user does not qualify
#         @QualificationAge = true
#         @QualificationGender = true
#         @QualificationComputer = true
#         @QualificationZip = true
#         @QualificationHhi = true
#         @QualificationPindustry = true
#         @QualificationChildren = true
#         @QualificationEducation = true
#         @QualificationEmployment = true
        
#         @QualificationJobTitle = true
#         @QualificationEthnicity = true
     
        
#         (0..project.datapoints.length-1).each do |m|
        
#           case project.datapoints[m]["name"]
#           when "Age"
#             # logic: once found true then set to true
#             @QualificationAge = false
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#               @QualificationAge = (project.datapoints[m]["values"][i]["min"]..project.datapoints[m]["values"][i]["max"]).include?(user.age.to_i) || @QualificationAge
#             end
#             # print "User entered age: ", user.age
#             # puts
#             # print "Project qual age: ", project.datapoints[m]["values"]
#             # puts
#             # print "@QualificationAge: ", @QualificationAge
#             # puts
            
#           when "Gender"
#             if project.datapoints[m]["values"].length == 2 then
#               @QualificationGender = true
#             else
#               if project.datapoints[m]["values"][0]["choice"] == user.gender.to_i then
#                 @QualificationGender = true
#               else
#                 @QualificationGender = false
#               end
#             end
#             # print "User entered gender: ", user.gender
#            #  puts
#            #  print "Project qual gender: ", project.datapoints[m]["values"]
#            #  puts
#            #  print "@QualificationGender: ", @QualificationGender
#            #  puts
           
           
#          when "Computer Check"
#            @QualificationComputer = false
#            (0..project.datapoints[m]["values"].length-1).each do |i|
#             if ((((project.datapoints[m]["values"][i]["choice"] == 1) || (project.datapoints[m]["values"][i]["choice"] == 2) || (project.datapoints[m]["values"][i]["choice"] == 4) || (project.datapoints[m]["values"][i]["choice"] == 5)) && (@MS_is_mobile == '&MS_is_mobile=false')) || (((project.datapoints[m]["values"][i]["choice"] == 3)) && (@MS_is_mobile == '&MS_is_mobile=true'))) then 
#               @QualificationComputer = true
#             else
#             end
#            end
#            print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>User computer type: ", @MS_is_mobile
#            puts
#            print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Project qualified computer types: ", project.datapoints[m]["values"]
#            puts
#            print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>@QualificationComputer: ", @QualificationComputer
#            puts
           
           
            
#           when "List of FSAs (CA)"
#             @QualificationZip = false
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#               if (project.datapoints[m]["values"][i]["freelist"]).include?(user.ZIP.slice(0..2)) then 
#                 @QualificationZip = true
#               else
#               end
#             end
#             # print "User entered SLICED zip: ", user.ZIP.slice(0..2)
#             # puts
#             # print "Project qual zip: ", project.datapoints[m]["values"]
#             # puts
#             # print "@QualificationZip: ", @QualificationZip
#             # puts
            
#           when "Household Income"
#             @QualificationHhi = false
#             @RFGHhi = ''
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#               if (project.datapoints[m]["values"][i]["choice"] == 1) && ( (user.householdincome.to_i == 1) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 2) && ( (user.householdincome.to_i == 2) || (user.householdincome.to_i == 3) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 3) && ( (user.householdincome.to_i == 4) || (user.householdincome.to_i == 5) || (user.householdincome.to_i == 6) || (user.householdincome.to_i == 7) || (user.householdincome.to_i == 8) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 4) && ( (user.householdincome.to_i == 9) || (user.householdincome.to_i == 10) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 5) && ( (user.householdincome.to_i == 11) || (user.householdincome.to_i == 12) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 6) && ( (user.householdincome.to_i == 13) || (user.householdincome.to_i == 14) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 7) && ( (user.householdincome.to_i == 15) || (user.householdincome.to_i == 16) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if ( (project.datapoints[m]["values"][i]["choice"] == 8) || (project.datapoints[m]["values"][i]["choice"] == 9) || (project.datapoints[m]["values"][i]["choice"] == 10) || (project.datapoints[m]["values"][i]["choice"] == 11) ) && ( (user.householdincome.to_i == 17) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end

#               print "===========================$$$$$$$$$$$$$$$$$$$$$$$============@RFGHhi===============: ", @RFGHhi
#               puts

#             end
#             # print "User entered HHI: ", user.householdincome
#             # puts
#             # print "Project qual HHI: ", project.datapoints[m]["values"]
#             # puts
#             # print "@QualificationHhi: ", @QualificationHhi
#             # puts
            
              
#           when "Employment Industry"
#             @QualificationPindustry = false
#             @RFGPindustry = ''
      
#             (0..project.datapoints[m]["values"].length-1).each do |i|

#               if (project.datapoints[m]["values"][i]["choice"] == 1) && (user.pindustry.to_i == 1) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 2) && (user.pindustry.to_i == 2) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 3) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 4) && (user.pindustry.to_i == 3) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 5) && (user.pindustry.to_i == 4) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 6) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 7) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 8) && (user.pindustry.to_i == 5) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 9) && (user.pindustry.to_i == 6) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 10) && (user.pindustry.to_i == 7) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 11) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 12) && (user.pindustry.to_i == 8) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 13) && (user.pindustry.to_i == 9) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 14) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 15) && (user.pindustry.to_i == 10) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 16) && (user.pindustry.to_i == 11) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 17) && (user.pindustry.to_i == 12) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 18) && (user.pindustry.to_i == 13) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 19) && (user.pindustry.to_i == 14) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 20) && (user.pindustry.to_i == 15) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 21) && (user.pindustry.to_i == 16) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 22) && (user.pindustry.to_i == 17) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 23) && (user.pindustry.to_i == 18) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 24) && (user.pindustry.to_i == 19) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 25) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 26) && (user.pindustry.to_i == 20) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 27) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 28) && (user.pindustry.to_i == 22) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 29) && (user.pindustry.to_i == 23) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 30) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 31) && (user.pindustry.to_i == 24) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 32) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 33) && (user.pindustry.to_i == 25) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 34) && (user.pindustry.to_i == 26) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 35) && (user.pindustry.to_i == 27) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 36) && (user.pindustry.to_i == 28) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 37) && (user.pindustry.to_i == 29) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 38) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 39) && (user.pindustry.to_i == 30) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 40) && (user.pindustry.to_i == 31) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 41) && (user.pindustry.to_i == 32) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 42) && (user.pindustry.to_i == 33) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 43) && (user.pindustry.to_i == 34) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 44) && (user.pindustry.to_i == 35) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 45) && (user.pindustry.to_i == 36) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 46) && (user.pindustry.to_i == 37) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 47) && (user.pindustry.to_i == 38) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 48) && (user.pindustry.to_i == 39) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 49) && (user.pindustry.to_i == 40) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 50) && (user.pindustry.to_i == 41) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 51) && (user.pindustry.to_i == 42) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 52) && (user.pindustry.to_i == 44) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 53) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 54) && (user.pindustry.to_i == 45) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 55) && (user.pindustry.to_i == 46) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 56) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 57) && (user.pindustry.to_i == 49) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 58) && (user.pindustry.to_i == 48) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 59) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 60) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 61) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 62) && ( (user.pindustry.to_i == 50) || (user.pindustry.to_i == 21) || (user.pindustry.to_i == 43) || (user.pindustry.to_i == 47) ) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 63) && (user.pindustry.to_i == 51) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
 
#             end
#             # print "User entered Pindustry: ", user.pindustry
#             # puts
#             # print "Project qual Pindustry: ", project.datapoints[m]["values"]
#             # puts
#             # print "@QualificationPindustry: ", @QualificationPindustry
#             # puts
          
# # Needs to be fixed as Min/Max qualification criteria for Children per Isaac's email
                  
#             when "Children"
#               @QualificationChildren = false
#               y=1
#               if user.children.include?("-3105") then
#                 @QualificationChildren = false
#               else
#                 (0..user.children.length-1).each do |c|
#                   (0..project.datapoints[m]["values"].length-1).each do |i|
#                     if (project.datapoints[m]["values"][i]["unit"]!=nil) then
#                       if (project.datapoints[m]["values"][i]["unit"]==0) then 
#                         y=1
#                       else
#                         y=12
#                       end
#                     else
#                       y=1
#                     end
#                     @QualificationChildren = (((project.datapoints[m]["values"][i]["min"]..project.datapoints[m]["values"][i]["max"]).include?(((user.children[c].to_f/2).round)*y)) && ((project.datapoints[m]["values"][i]["gender"] == nil) || (user.children[c].to_i % 2==project.datapoints[m]["values"][i]["gender"].to_i % 2))) || @QualificationChildren
#                   end
#                 end
#               end
#               print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> User entered Children: ", user.children
#               puts
#               print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Project qual Children: ", project.datapoints[m]["values"]
#               puts
#               print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> @QualificationChildren: ", @QualificationChildren
#               puts   
  
#           # when "Children Age and Gender"
# #               @QualificationChildren = false
# #               (0..project.datapoints[m]["values"].length-1).each do |i|
# #                 if ((project.datapoints[m]["values"][i]["choice"].to_s & user.children).empty? == false) then
# #                   @QualificationChildren = true
# #                 else
# #                 end
# #               end
# #               # print "User entered Children: ", user.children
# #               # puts
# #               # print "Project qual Children: ", project.datapoints[m]["values"]
# #               # puts
# #               # print "@QualificationChildren: ", @QualificationChildren
# #               # puts
                  
#           when "Education (CA)"
#             @QualificationEducation = false
#             @RFGEducationCA = ''
            
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#               if (project.datapoints[m]["values"][i]["choice"] == 1) && (user.eduation.to_i == 1) then
#                   @QualificationEducation = true
#                   @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end 
#               if (project.datapoints[m]["values"][i]["choice"] == 2) && ((user.eduation.to_i == 2) || (user.eduation.to_i == 3)) then
#                 @QualificationEducation = true
#                 @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
#               if (project.datapoints[m]["values"][i]["choice"] == 3) && (user.eduation.to_i == 4) then
#                 @QualificationEducation = true
#                 @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
#               if (project.datapoints[m]["values"][i]["choice"] == 4) && ((user.eduation.to_i == 5) || (user.eduation.to_i == 6))  then
#                 @QualificationEducation = true
#                 @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
#               if (project.datapoints[m]["values"][i]["choice"] == 5) && ((user.eduation.to_i == 7) || (user.eduation.to_i == 8))  then
#                 @QualificationEducation = true
#                 @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
#               if (project.datapoints[m]["values"][i]["choice"] == 6) && (user.eduation.to_i == 9) then
#                 @QualificationEducation = true
#                 @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end                    
#               if (project.datapoints[m]["values"][i]["choice"] == 7) && ((user.eduation.to_i == 10) || (user.eduation.to_i == 11))  then
#                 @QualificationEducation = true
#                 @RFGEducationCA = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
#             end
              
#             # print "User entered Education: ", user.eduation
#             # puts
#             # print "Project qual Education: ", project.datapoints[m]["values"]
#             # puts
#             # print "@QualificationEducation: ", @QualificationEducation
#             # puts


#           when "Job Title"
#               @QualificationJobTitle = false
#               @RFGJobTitle = ''
              
#               (0..project.datapoints[m]["values"].length-1).each do |i|
                                
#                 if (project.datapoints[m]["values"][i]["choice"] == 2) && (user.jobtitle.to_i == 1) then
#                   @QualificationJobTitle = true
#                   @RFGJobTitle = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 3) && ((user.jobtitle.to_i == 2) ||  (user.jobtitle.to_i == 3)) then
#                   @QualificationJobTitle = true
#                   @RFGJobTitle = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 4) && (user.jobtitle.to_i == 4) then
#                   @QualificationJobTitle = true
#                   @RFGJobTitle = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end  
#                 if (project.datapoints[m]["values"][i]["choice"] > 4) then
#                   @QualificationJobTitle = true
#                   @RFGJobTitle = ''
#                 else
#                 end
                                 
#               end
#               # print "User entered JobTitle: ", user.jobtitle
#               # puts
#               # print "Project qual JobTitle: ", project.datapoints[m]["values"]
#               # puts
#               # print "@QualificationJobTitle: ", @QualificationJobTitle
#               # puts
                    
                        
#             when "Employment Status"
#               @QualificationEmployment = false
#               @RFGEmployment = ''
              
#               (0..project.datapoints[m]["values"].length-1).each do |i|
#               if (project.datapoints[m]["values"][i]["choice"] == 1) && (user.employment.to_i == 10) then
#                 @QualificationEmployment = true
#                 @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end 
#                       if (project.datapoints[m]["values"][i]["choice"] == 2) && (user.employment.to_i == 2) then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                       if (project.datapoints[m]["values"][i]["choice"] == 3) && (user.employment.to_i == 1) then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                       if (project.datapoints[m]["values"][i]["choice"] == 4) && (user.employment.to_i == 7)  then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                       if (project.datapoints[m]["values"][i]["choice"] == 5) && (user.employment.to_i == 9)  then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                       if (project.datapoints[m]["values"][i]["choice"] == 6) && ((user.employment.to_i == 3) || (user.employment.to_i == 4)) then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end                    
#                       if (project.datapoints[m]["values"][i]["choice"] == 7) && (user.employment.to_i == 8)  then
#                         @QualificationEmployment = true
#                         @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                       else
#                       end
#                     end
#           # print "User entered Employment: ", user.employment
#           # puts
#           # print "Project qual Employment: ", project.datapoints[m]["values"]
#           # puts
#           # print "@QualificationEmployment: ", @QualificationEmployment
#           # puts
          
          
#           end # case statement
#         end # do m
        
        
#         print " QUALIFICATIONS CRITERIA for: ", project.rfg_id
#         puts
#         print "country = ", (project.country == "CA")
#         puts
#         print "cpi = ", (project.cpi > @currentpayoutstr)
#         puts        
#         print "Live = ", (project.projectStillLive)
#         puts
#         print "Age = ", (@QualificationAge)
#         puts
#         print "Gender = ", (@QualificationGender)
#         puts
#         print "Computer = ", (@QualificationComputer)
#         puts
#         print "Zip = ", (@QualificationZip)
#         puts
#         print "HHI = ", (@QualificationHhi)
#         puts
#         print "PIndustry = ", (@QualificationPindustry)
#         puts
#         print "Education = ", (@QualificationEducation)
#         puts
#         print "Employment = ", (@QualificationEmployment)
#         puts
#         print "JobTitle = ", (@QualificationJobTitle)
#         puts
#         print "Ethnicity = ", (@QualificationEthnicity)
#         puts
#         print "Children = ", (@QualificationChildren)
#         puts
        
         
#         if ( (project.country == "CA") && ( project.projectStillLive ) && (project.cpi > @currentpayoutstr) && ( @QualificationAge ) && ( @QualificationGender ) && (@QualificationComputer) && ( @QualificationZip ) && ( @QualificationHhi ) && ( @QualificationPindustry ) && ( @QualificationEducation ) && ( @QualificationEmployment ) && (@QualificationChildren) && (@QualificationJobTitle) && (@QualificationEthnicity) ) then
          
#           @RFGQualifiedProjects << project.rfg_id
          
#           print '********** In total USER_ID: ', user.user_id, ' has QUALIFIED for the following RFG projects: ', @RFGQualifiedProjects
#           puts
          

#           # Verify if there is a quota for the qualified user and if it is full
          
#           if project.quotas.length > 0 then 
#             # @RFGQuotaIsAvailable = false # initialize quota availability as false, then check quotas to prove/disprove
#            # @RFGQuotaFull = false
           
#             print "--------------------------------------------------------------->>>>>>>>> NUMBER OF QUOTAS = ", project.quotas.length
#             puts
            
#             (0..project.quotas.length-1).each do |j|
#               (0..project.quotas[j]["datapoints"].length-1).each do |n|
            
#               # Assume quota per qualifications is available. These are turned false if user does not qualify
#               @QualificationAge = true
#               @QualificationGender = true
#               @QualificationComputer = true
#               @QualificationZip = true
#               @QualificationHhi = true
#               @QualificationPindustry = true
#               @QualificationChildren = true
#               @QualificationEducation = true
#               @QualificationEmployment = true              
                                        
#               case project.quotas[j]["datapoints"][n]["name"]
#               when "Age"
#                 #logic: once found true then turn to true
#                 @QualificationAge = false
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                   @QualificationAge = (project.quotas[j]["datapoints"][n]["values"][i]["min"]..project.quotas[j]["datapoints"][n]["values"][i]["max"]).include?(user.age.to_i) || @QualificationAge
#                 end
#                 # print "User entered age: ", user.age
#                 # puts
#                 # print "Project quota age: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 # print "Quota for @QualificationAge: ", @QualificationAge
#                 # puts
            
#               when "Gender"
#                 if project.quotas[j]["datapoints"][n]["values"].length == 2 then
#                   @QualificationGender = true
#                 else
#                   if project.quotas[j]["datapoints"][n]["values"][0]["choice"] == user.gender.to_i then
#                     @QualificationGender = true
#                   else
#                     @QualificationGender = false
#                   end
#                 end
#                 # print "User entered gender: ", user.gender
#                 # puts
#                 # print "Project quota gender: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 # print "Quota for @QualificationGender: ", @QualificationGender
#                 # puts
                
                
#               when "Computer Check"
#                 @QualificationComputer = false
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                  if ((((project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5)) && (@MS_is_mobile == '&MS_is_mobile=false')) || (((project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3)) && (@MS_is_mobile == '&MS_is_mobile=true'))) then 
#                    @QualificationComputer = true
#                  else
#                  end
#                 end
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>User computer type: ", @MS_is_mobile
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Project quota for computer types: ", project.quotas[j]["datapoints"][n]["values"]
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>@QualificationComputer: ", @QualificationComputer
#                 puts
                
                
            
#               when "List of FSAs (CA)"
#                 @QualificationZip = false
#                 print "Project qual zip: ", project.quotas[j]["datapoints"][n]["values"]
#                 puts
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["freelist"]).include?(user.ZIP.slice(0..2)) then 
#                     @QualificationZip = true
#                   else
#                   end
#                 end
#                 # print "User entered SLICED zip: ", user.ZIP.slice(0..2)
#                 # puts
#                 #
#                 # print "Quota for @QualificationZip: ", @QualificationZip
#                 # puts
            
#               when "Household Income"
#                 @QualificationHhi = false
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                     
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && ( (user.householdincome.to_i == 1) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && ( (user.householdincome.to_i == 2) || (user.householdincome.to_i == 3) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && ( (user.householdincome.to_i == 4) || (user.householdincome.to_i == 5) || (user.householdincome.to_i == 6) || (user.householdincome.to_i == 7) || (user.householdincome.to_i == 8) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && ( (user.householdincome.to_i == 9) || (user.householdincome.to_i == 10) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && ( (user.householdincome.to_i == 11) || (user.householdincome.to_i == 12) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && ( (user.householdincome.to_i == 13) || (user.householdincome.to_i == 14) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && ( (user.householdincome.to_i == 15) || (user.householdincome.to_i == 16) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if ( (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 8) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 9) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 10) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 11) ) && ( (user.householdincome.to_i == 17) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
#                 end
#                 # print "User entered HHI: ", user.householdincome
#                 # puts
#                 # print "Project HHI quota: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 # print "Quota for @QualificationHhi: ", @QualificationHhi
#                 # puts
                  
                  
#                 when "Employment Industry"
#                   @QualificationPindustry = false
      
#                   (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|

#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && (user.pindustry.to_i == 1) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && (user.pindustry.to_i == 2) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && (user.pindustry.to_i == 3) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && (user.pindustry.to_i == 4) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 8) && (user.pindustry.to_i == 5) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 9) && (user.pindustry.to_i == 6) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 10) && (user.pindustry.to_i == 7) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 11) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 12) && (user.pindustry.to_i == 8) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 13) && (user.pindustry.to_i == 9) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 14) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 15) && (user.pindustry.to_i == 10) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 16) && (user.pindustry.to_i == 11) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 17) && (user.pindustry.to_i == 12) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 18) && (user.pindustry.to_i == 13) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 19) && (user.pindustry.to_i == 14) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 20) && (user.pindustry.to_i == 15) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 21) && (user.pindustry.to_i == 16) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 22) && (user.pindustry.to_i == 17) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 23) && (user.pindustry.to_i == 18) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 24) && (user.pindustry.to_i == 19) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 25) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 26) && (user.pindustry.to_i == 20) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 27) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 28) && (user.pindustry.to_i == 22) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 29) && (user.pindustry.to_i == 23) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 30) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 31) && (user.pindustry.to_i == 24) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 32) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 33) && (user.pindustry.to_i == 25) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 34) && (user.pindustry.to_i == 26) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 35) && (user.pindustry.to_i == 27) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 36) && (user.pindustry.to_i == 28) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 37) && (user.pindustry.to_i == 29) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 38) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 39) && (user.pindustry.to_i == 30) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 40) && (user.pindustry.to_i == 31) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 41) && (user.pindustry.to_i == 32) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 42) && (user.pindustry.to_i == 33) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 43) && (user.pindustry.to_i == 34) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 44) && (user.pindustry.to_i == 35) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 45) && (user.pindustry.to_i == 36) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 46) && (user.pindustry.to_i == 37) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 47) && (user.pindustry.to_i == 38) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 48) && (user.pindustry.to_i == 39) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 49) && (user.pindustry.to_i == 40) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 50) && (user.pindustry.to_i == 41) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 51) && (user.pindustry.to_i == 42) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 52) && (user.pindustry.to_i == 44) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 53) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 54) && (user.pindustry.to_i == 45) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 55) && (user.pindustry.to_i == 46) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 56) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 57) && (user.pindustry.to_i == 49) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 58) && (user.pindustry.to_i == 48) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 59) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 60) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 61) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 62) && ( (user.pindustry.to_i == 50) || (user.pindustry.to_i == 21) || (user.pindustry.to_i == 43) || (user.pindustry.to_i == 47) ) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 63) && (user.pindustry.to_i == 51) then
#                       @QualificationPindustry = true
#                     else
#                     end                  
#                 end
#                 # print "User entered Pindustry: ", user.pindustry
#                 # puts
#                 # print "Project quota Pindustry: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 # print "Quota for @QualificationPindustry: ", @QualificationPindustry
#                 # puts
              
#               when "Children"
#                 @QualificationChildren = false
#                 y=1
#                 if user.children.include?("-3105") then
#                   @QualificationChildren = false
#                 else
#                   (0..user.children.length-1).each do |c|
#                     (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                       if (project.quotas[j]["datapoints"][n]["values"][i]["unit"]!=nil) then
#                         if (project.quotas[j]["datapoints"][n]["values"][i]["unit"]==0) then 
#                           y=1
#                         else
#                           y=12
#                         end
#                       else
#                         y=1
#                       end
#                       @QualificationChildren = (((project.quotas[j]["datapoints"][n]["values"][i]["min"]..project.quotas[j]["datapoints"][n]["values"][i]["max"]).include?(((user.children[c].to_f/2).round)*y)) && ((project.quotas[j]["datapoints"][n]["values"][i]["gender"] == nil) || (user.children[c].to_i % 2==project.quotas[j]["datapoints"][n]["values"][i]["gender"].to_i % 2))) || @QualificationChildren
#                     end
#                   end
#                 end
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> User entered Children: ", user.children
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Project quota Children: ", project.quotas[j]["datapoints"][n]["values"]
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Quota for @QualificationChildren: ", @QualificationChildren
#                 puts    
              
             
#               # when "Children Age and Gender"
# #                   @QualificationChildren = false
# #                   (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
# #                     if ((project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s & user.children).empty? == false) then
# #                       @QualificationChildren = true
# #                     else
# #                     end
# #                   end
# #                   # print "User entered Children: ", user.children
# #                   # puts
# #                   # print "Project quota Children: ", project.quotas[j]["datapoints"][n]["values"]
# #                   # puts
# #                   # print "@QualificationChildren: ", @QualificationChildren
# #                   # puts
                  
#               when "Education (CA)"
#                   @QualificationEducation = false
#                   (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && (user.eduation.to_i == 1) then
#                       @QualificationEducation = true
#                       @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end 
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && ((user.eduation.to_i == 2) || (user.eduation.to_i == 3)) then
#                     @QualificationEducation = true
#                     @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && (user.eduation.to_i == 4) then
#                     @QualificationEducation = true
#                     @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && ((user.eduation.to_i == 5) || (user.eduation.to_i == 6))  then
#                     @QualificationEducation = true
#                     @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && ((user.eduation.to_i == 7) || (user.eduation.to_i == 8))  then
#                     @QualificationEducation = true
#                     @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && (user.eduation.to_i == 9) then
#                     @QualificationEducation = true
#                     @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end                    
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && ((user.eduation.to_i == 10) || (user.eduation.to_i == 11))  then
#                     @QualificationEducation = true
#                     @RFGEducationCA = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                 end
#                 # print "User entered Education: ", user.eduation
#                 # puts
#                 # print "Project quota Education: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 # print "Quota for @QualificationEducation: ", @QualificationEducation
#                 # puts
                        
#                 when "Employment Status"
#                   @QualificationEmployment = false
#                   (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && (user.employment.to_i == 10) then
#                     @QualificationEmployment = true
#                     @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end 
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && (user.employment.to_i == 2) then
#                             @QualificationEmployment = true
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && (user.employment.to_i == 1) then
#                             @QualificationEmployment = true
#                             print "----------->>> project employment choice: ", project.quotas[j]["datapoints"][n]["values"][i]["choice"], 'and user.employment: ', user.employment
#                             puts 
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && (user.employment.to_i == 7)  then
#                             @QualificationEmployment = true
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && (user.employment.to_i == 9)  then
#                             @QualificationEmployment = true
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && ((user.employment.to_i == 3) || (user.employment.to_i == 4)) then
#                             @QualificationEmployment = true
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end                    
#                           if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && (user.employment.to_i == 8)  then
#                             @QualificationEmployment = true
#                             @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                           else
#                           end
#                         end
#               # print "User entered Employment: ", user.employment
#               # puts
#               # print "Project quota Employment: ", project.quotas[j]["datapoints"][n]["values"]
#               # puts
#               # print "Quota for @QualificationEmployment: ", @QualificationEmployment
#               # puts
              
#               end # case
              

#               if project.quotas[j]["datapoints"][n]["completesLeft"] == nil then
#                 @QuotaCompletesLeft = true
#                 p "************* RFG CompletesLeft is UNDEFINED ***************"
#               else 
#                 if (project.quotas[j]["datapoints"][n]["completesLeft"] > 0) then
#                   @QuotaCompletesLeft = true
#                   p "************* RFG CompletesLeft is > 0  ***************"

#                 else
#                   @QuotaCompletesLeft = false
#                   p "************* RFG CompletesLeft is = 0  ***************"
#                 end
#               end


              
#               print " QUOTA AVAILABILITY CRITERIA for: ", project.rfg_id
#               puts
#               print "country = ", (project.country == "CA")
#               puts
#               print "Age = ", (@QualificationAge)
#               puts
#               print "Gender = ", (@QualificationGender)
#               puts
#               print "Computer = ", (@QualificationComputer)
#               puts
#               print "Zip = ", (@QualificationZip)
#               puts
#               print "HHI = ", (@QualificationHhi)
#               puts
#               print "PIndustry = ", (@QualificationPindustry)
#               puts
#               print "Education = ", (@QualificationEducation)
#               puts
#               print "Employment = ", (@QualificationEmployment)
#               puts
#               print "Children = ", (@QualificationChildren)
#               puts
#               print "CompletesLeft = ", (@QuotaCompletesLeft)
#               puts

              
#               if ( (project.country == "CA") && ( @QualificationAge ) && ( @QualificationGender ) && (@QualificationComputer) && ( @QualificationZip ) && ( @QualificationHhi ) && ( @QualificationPindustry ) && ( @QualificationEducation ) && ( @QualificationEducation ) && (@QualificationEmployment) && (@QualificationChildren) && (@QuotaCompletesLeft) ) then
              
#                 @RFGQuotaIsAvailable = true
#                 puts "******* Quota is available"
#               else
#                 # if previous quota was available then preserve that fact
#                 @RFGQuotaIsAvailable = false || @RFGQuotaIsAvailable
#               end
              
#               end # reviewed all n nested qualifications of a quota
                           
#             end # all j quotas have been inspected

#           else            
#             print "************** Quota available: There are no quota restrictions"
#             puts
            
#             @RFGQuotaIsAvailable = true
            
#           end # quotaavailable?
          
#           if @RFGQuotaIsAvailable == true then
          
#             print '********** USER_ID: ', user.user_id, ' has Quota for the RFG project: ', project.rfg_id
#             puts
           
#             print "--------------*************** Checking for duplicate user fingerprint for project number: ", project.rfg_id
#             puts
                  
#             # lets assume the user is not a duplicate, typically
#             @duplicateFingerprint = false
        
#             if user.fingerprint != nil then
        
#               print "--------------->>>>>>******************* user fingerprint: ", user.fingerprint
#               puts
        
#               command = { :command => "livealert/duplicateCheck/1", :rfg_id => project.rfg_id, :fingerprint => user.fingerprint, :ip => user.ip_address }.to_json
                    
#               time=Time.now.to_i
#               hash = Digest::HMAC.hexdigest("#{time}#{command}", secret.scan(/../).map {|x| x.to_i(16).chr}.join, Digest::SHA1)
#               uri = URI("https://www.saysoforgood.com/API?apid=#{apid}&time=#{time}&hash=#{hash}")
            
#               begin
#                 Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
#                   req = Net::HTTP::Post.new uri
#                   req.body = command
#                   req.content_type = 'application/json'
#                   response = http.request req
#                   @RFGFingerprint = JSON.parse(response.body)  
#                 end
                    
#                 rescue Net::ReadTimeout => e  
#                 puts e.message
#               end
              
#               print "******************* Fingerprint 1, result: ", @RFGFingerprint, ' ', @RFGFingerprint["result"]
#               puts
                      
#               if ((@RFGFingerprint == nil) || (@RFGFingerprint["result"] != 0))  then
#                 @duplicateFingerprint = true            
#                 puts "----------->>>>>> @RFGFingerprint response returned by rfg server was not valid. User will not be allowed to enter, ZZZZZZZZ"
            
#               else
                        
#                 print "******************* Fingerprint 2, isDuplicate?: ", @RFGFingerprint, ' ', @RFGFingerprint["response"]["isDuplicate"]
#                 puts
                      
#                 if @RFGFingerprint["response"]["isDuplicate"] == true then
#                   @duplicateFingerprint = true
#                   puts "----------->>>>>> @RFGFingerprint response returned by rfg server was true. User will not be allowed to enter, XXXXXXXX"             
#                 else
#                   @duplicateFingerprint = false
#                   puts "----------->>>>>> @RFGFingerprint response returned by rfg server was false, User can enter VVVVVVVVVV"
#                 end
              
#               end      
                 
#             else
#               # Force it to be not duplicate because it had no fingerprint
#               @duplicateFingerprint = false          
#               puts "----------->>>>>> user fingerprint was nil. User can enter, CCCCCCCCC"
          
#             end # fingerprint == nil
            
#             if  @duplicateFingerprint == false then
                 
#               print "*************** This is not a duplicate user for this project. Add to list of projects for userride", project.rfg_id
#               puts
              
#               if (@RFGProjectsWithQuota.length == 0) then
#                 @RFGProjectsWithQuota << project.rfg_id
#                 @RFGSupplierLinks << project.link+'&rfg_id='+project.rfg_id
#               else
#                 @inserted = false
#                 (0..@RFGProjectsWithQuota.length-1).each do |i|
#                   @project1 = RfgProject.where('rfg_id = ?', @RFGProjectsWithQuota[i]).first
#                   if ( (project.estimatedIR > @project1.estimatedIR) && (@inserted == false) ) then
#                     @RFGProjectsWithQuota.insert(i, project.rfg_id)
#                     @RFGSupplierLinks.insert(i, project.link+'&rfg_id='+project.rfg_id)
#                     @inserted = true
#                   else
#                   end
#                 end
#               end
                        
#               if (@RFGProjectsWithQuota.uniq.length >= @RFG_CA) then
#                 @foundtopprojectswithquota = true
#               else  
#                 #do nothing
#               end             
              
#             else
            
#               print '-------------->>> DUPLICATE: Skip this project as User has already completed this project', project.rfg_id
#               puts
          
#             end # if @duplicateFingerprint
            
#           else
            
#             print '********** USER_ID: ', user.user_id, ' DOES NOT HAVE ANY Quota available for the RFG projects: ', project.rfg_id
#             puts
#           end # if quota available = true
          
#         else
          
#           print '************ User DID NOT QUALIFY for project number = ', project.rfg_id
#           puts
          
#         end # Qualification check

#         else
#         end # if projectStillLive
 
#       else
#       end # if foundtopprojects
      
#     end # do all projects
    
#     else
#     end # country = "6"
    
    
#     if user.country == "5" then  
              
#     #RfgProject.where("country = ? AND state = ?", user_country, 2).order(epc: :desc).order(projectEPC: :desc).each do |project|
#     RfgProject.where("country = ? AND state = ?", user_country, 2).order(estimatedIR: :desc).order(projectEPC: :desc).each do |project|
#       if @foundtopprojectswithquota == false then  #3 false means not finished finding top projects     
        
#         if project.projectStillLive then
                
#         # Initialize qualification parameters to true. These are turned false if user does not qualify
#         @QualificationAge = true
#         @QualificationGender = true
#         @QualificationComputer = true
#         @QualificationZip = true
#         @QualificationHhi = true
#         @QualificationPindustry = true
#         @QualificationChildren = true
#         @QualificationEducation = true
#         @QualificationEmployment = true
        
#         @QualificationJobTitle = true
#         @QualificationEthnicity = true
     
        
#         (0..project.datapoints.length-1).each do |m|
        
#           case project.datapoints[m]["name"]
#           when "Age"
#             # logic: once found true then set to true
#             @QualificationAge = false
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#               @QualificationAge = (project.datapoints[m]["values"][i]["min"]..project.datapoints[m]["values"][i]["max"]).include?(user.age.to_i) || @QualificationAge
#             end
#             # print "User entered age: ", user.age
#             # puts
#             # print "Project qual age: ", project.datapoints[m]["values"]
#             # puts
#             # print "@QualificationAge: ", @QualificationAge
#             # puts
            
#           when "Gender"
#             if project.datapoints[m]["values"].length == 2 then
#               @QualificationGender = true
#             else
#               if project.datapoints[m]["values"][0]["choice"] == user.gender.to_i then
#                 @QualificationGender = true
#               else
#                 @QualificationGender = false
#               end
#             end
#             # print "User entered gender: ", user.gender
#             # puts
#             # print "Project qual gender: ", project.datapoints[m]["values"]
#             # puts
#             # print "@QualificationGender: ", @QualificationGender
#             # puts
            
            
#           when "Computer Check"
#             @QualificationComputer = false
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#              if ((((project.datapoints[m]["values"][i]["choice"] == 1) || (project.datapoints[m]["values"][i]["choice"] == 2) || (project.datapoints[m]["values"][i]["choice"] == 4) || (project.datapoints[m]["values"][i]["choice"] == 5)) && (@MS_is_mobile == '&MS_is_mobile=false')) || (((project.datapoints[m]["values"][i]["choice"] == 3)) && (@MS_is_mobile == '&MS_is_mobile=true'))) then 
#                @QualificationComputer = true
#              else
#              end
#             end
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>User computer type: ", @MS_is_mobile
#             puts
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Project qualified computer types: ", project.datapoints[m]["values"]
#             puts
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>@QualificationComputer: ", @QualificationComputer
#             puts
            
            
            
#           # when "List of FSAs (AU)"
# #             @QualificationZip = false
# #             (0..project.datapoints[m]["values"].length-1).each do |i|
# #               if (project.datapoints[m]["values"][i]["freelist"]).include?(user.ZIP.slice(0..2)) then
# #                 @QualificationZip = true
# #               else
# #               end
# #             end
# #             print "User entered SLICED zip: ", user.ZIP.slice(0..2)
# #             puts
# #             print "Project qual zip: ", project.datapoints[m]["values"]
# #             puts
# #             print "@QualificationZip: ", @QualificationZip
# #             puts
            
#           when "Household Income"
#             @QualificationHhi = false
#             @RFGHhi = ''
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#               if (project.datapoints[m]["values"][i]["choice"] == 1) && ( (user.householdincome.to_i == 1) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
# #             puts
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 2) && ( (user.householdincome.to_i == 2) || (user.householdincome.to_i == 3) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 3) && ( (user.householdincome.to_i == 4) || (user.householdincome.to_i == 5) || (user.householdincome.to_i == 6) || (user.householdincome.to_i == 7) || (user.householdincome.to_i == 8) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 4) && ( (user.householdincome.to_i == 9) || (user.householdincome.to_i == 10) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 5) && ( (user.householdincome.to_i == 11) || (user.householdincome.to_i == 12) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 6) && ( (user.householdincome.to_i == 13) || (user.householdincome.to_i == 14) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 7) && ( (user.householdincome.to_i == 15) || (user.householdincome.to_i == 16) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if ( (project.datapoints[m]["values"][i]["choice"] == 8) || (project.datapoints[m]["values"][i]["choice"] == 9) || (project.datapoints[m]["values"][i]["choice"] == 10) || (project.datapoints[m]["values"][i]["choice"] == 11) ) && ( (user.householdincome.to_i == 17) || (user.householdincome.to_i == 18) ) then
#                 @QualificationHhi = true
#                 @RFGHhi = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end

#               print "===========================$$$$$$$$$$$$$$$$$$$$$$$============@RFGHhi===============: ", @RFGHhi
#               puts

#             end
#             # print "User entered HHI: ", user.householdincome
#             # puts
#             # print "Project qual HHI: ", project.datapoints[m]["values"]
#             # puts
#             # print "@QualificationHhi: ", @QualificationHhi
#             # puts
                          
#           when "Employment Industry"
#             @QualificationPindustry = false
#             @RFGPindustry = ''
      
#             (0..project.datapoints[m]["values"].length-1).each do |i|

#               if (project.datapoints[m]["values"][i]["choice"] == 1) && (user.pindustry.to_i == 1) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 2) && (user.pindustry.to_i == 2) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 3) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 4) && (user.pindustry.to_i == 3) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 5) && (user.pindustry.to_i == 4) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 6) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 7) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 8) && (user.pindustry.to_i == 5) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 9) && (user.pindustry.to_i == 6) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 10) && (user.pindustry.to_i == 7) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 11) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 12) && (user.pindustry.to_i == 8) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 13) && (user.pindustry.to_i == 9) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 14) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 15) && (user.pindustry.to_i == 10) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 16) && (user.pindustry.to_i == 11) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 17) && (user.pindustry.to_i == 12) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 18) && (user.pindustry.to_i == 13) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 19) && (user.pindustry.to_i == 14) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 20) && (user.pindustry.to_i == 15) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 21) && (user.pindustry.to_i == 16) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 22) && (user.pindustry.to_i == 17) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 23) && (user.pindustry.to_i == 18) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 24) && (user.pindustry.to_i == 19) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 25) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 26) && (user.pindustry.to_i == 20) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 27) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 28) && (user.pindustry.to_i == 22) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 29) && (user.pindustry.to_i == 23) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 30) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 31) && (user.pindustry.to_i == 24) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 32) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 33) && (user.pindustry.to_i == 25) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 34) && (user.pindustry.to_i == 26) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 35) && (user.pindustry.to_i == 27) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 36) && (user.pindustry.to_i == 28) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 37) && (user.pindustry.to_i == 29) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 38) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 39) && (user.pindustry.to_i == 30) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 40) && (user.pindustry.to_i == 31) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 41) && (user.pindustry.to_i == 32) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 42) && (user.pindustry.to_i == 33) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 43) && (user.pindustry.to_i == 34) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 44) && (user.pindustry.to_i == 35) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 45) && (user.pindustry.to_i == 36) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 46) && (user.pindustry.to_i == 37) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 47) && (user.pindustry.to_i == 38) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 48) && (user.pindustry.to_i == 39) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 49) && (user.pindustry.to_i == 40) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 50) && (user.pindustry.to_i == 41) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 51) && (user.pindustry.to_i == 42) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 52) && (user.pindustry.to_i == 44) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 53) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 54) && (user.pindustry.to_i == 45) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 55) && (user.pindustry.to_i == 46) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 56) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 57) && (user.pindustry.to_i == 49) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 58) && (user.pindustry.to_i == 48) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 59) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 60) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 61) && (user.pindustry.to_i == 50) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 62) && ( (user.pindustry.to_i == 50) || (user.pindustry.to_i == 21) || (user.pindustry.to_i == 43) || (user.pindustry.to_i == 47) ) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
              
#               if (project.datapoints[m]["values"][i]["choice"] == 63) && (user.pindustry.to_i == 51) then
#                 @QualificationPindustry = true
#                 @RFGPindustry = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
 
#             end
#             # print "User entered Pindustry: ", user.pindustry
#             # puts
#             # print "Project qual Pindustry: ", project.datapoints[m]["values"]
#             # puts
#             # print "@QualificationPindustry: ", @QualificationPindustry
#             # puts
                    
#           when "Children"
#             @QualificationChildren = false
#             y=1
#             if user.children.include?("-3105") then
#               @QualificationChildren = false
#             else
#               (0..user.children.length-1).each do |c|
#                 (0..project.datapoints[m]["values"].length-1).each do |i|
#                   if (project.datapoints[m]["values"][i]["unit"]!=nil) then
#                     if (project.datapoints[m]["values"][i]["unit"]==0) then 
#                       y=1
#                     else
#                       y=12
#                     end
#                   else
#                     y=1
#                   end
#                   @QualificationChildren = (((project.datapoints[m]["values"][i]["min"]..project.datapoints[m]["values"][i]["max"]).include?(((user.children[c].to_f/2).round)*y)) && ((project.datapoints[m]["values"][i]["gender"] == nil) || (user.children[c].to_i % 2==project.datapoints[m]["values"][i]["gender"].to_i % 2))) || @QualificationChildren
#                 end
#               end
#             end
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> User entered Children: ", user.children
#             puts
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Project qual Children: ", project.datapoints[m]["values"]
#             puts
#             print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> @QualificationChildren: ", @QualificationChildren
#             puts          
          
#           # when "Children Age and Gender"
# #               @QualificationChildren = false
# #               (0..project.datapoints[m]["values"].length-1).each do |i|
# #                 if ((project.datapoints[m]["values"][i]["choice"].to_s & user.children).empty? == false) then
# #                   @QualificationChildren = true
# #                 else
# #                 end
# #               end
# #               # print "User entered Children: ", user.children
# #               # puts
# #               # print "Project qual Children: ", project.datapoints[m]["values"]
# #               # puts
# #               # print "@QualificationChildren: ", @QualificationChildren
# #               # puts
                  
#           when "Education (AU)"
#             @QualificationEducation = false
#             @RFGEducationAU = ''
            
#             (0..project.datapoints[m]["values"].length-1).each do |i|
#               if (project.datapoints[m]["values"][i]["choice"] == 1) && (user.eduation.to_i == 1) then
#                   @QualificationEducation = true
#                   @RFGEducationAU = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end 
#               if (project.datapoints[m]["values"][i]["choice"] == 2) && ((user.eduation.to_i == 2) || (user.eduation.to_i == 3)) then
#                 @QualificationEducation = true
#                 @RFGEducationAU = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
#               if (project.datapoints[m]["values"][i]["choice"] == 3) && (user.eduation.to_i == 4) then
#                 @QualificationEducation = true
#                 @RFGEducationAU = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
#               if (project.datapoints[m]["values"][i]["choice"] == 4) && ((user.eduation.to_i == 5) || (user.eduation.to_i == 6))  then
#                 @QualificationEducation = true
#                 @RFGEducationAU = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
#               if (project.datapoints[m]["values"][i]["choice"] == 5) && ((user.eduation.to_i == 7) || (user.eduation.to_i == 8))  then
#                 @QualificationEducation = true
#                 @RFGEducationAU = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
#               if (project.datapoints[m]["values"][i]["choice"] == 6) && (user.eduation.to_i == 9) then
#                 @QualificationEducation = true
#                 @RFGEducationAU = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end                    
#               if (project.datapoints[m]["values"][i]["choice"] == 7) && ((user.eduation.to_i == 10) || (user.eduation.to_i == 11))  then
#                 @QualificationEducation = true
#                 @RFGEducationAU = project.datapoints[m]["values"][i]["choice"].to_s
#               else
#               end
#             end
              
#             # print "User entered Education: ", user.eduation
#             # puts
#             # print "Project qual Education: ", project.datapoints[m]["values"]
#             # puts
#             # print "@QualificationEducation: ", @QualificationEducation
#             # puts


#             when "Job Title"
#                 @QualificationJobTitle = false
#                 @RFGJobTitle = ''
                
#                 (0..project.datapoints[m]["values"].length-1).each do |i|
                                  
#                   if (project.datapoints[m]["values"][i]["choice"] == 2) && (user.jobtitle.to_i == 1) then
#                     @QualificationJobTitle = true
#                     @RFGJobTitle = project.datapoints[m]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.datapoints[m]["values"][i]["choice"] == 3) && ((user.jobtitle.to_i == 2) ||  (user.jobtitle.to_i == 3)) then
#                     @QualificationJobTitle = true
#                     @RFGJobTitle = project.datapoints[m]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.datapoints[m]["values"][i]["choice"] == 4) && (user.jobtitle.to_i == 4) then
#                     @QualificationJobTitle = true
#                     @RFGJobTitle = project.datapoints[m]["values"][i]["choice"].to_s
#                   else
#                   end  
#                   if (project.datapoints[m]["values"][i]["choice"] > 4) then
#                     @QualificationJobTitle = true
#                     @RFGJobTitle = ''
#                   else
#                   end
                                   
#                 end
#                 # print "User entered JobTitle: ", user.jobtitle
#                 # puts
#                 # print "Project qual JobTitle: ", project.datapoints[m]["values"]
#                 # puts
#                 # print "@QualificationJobTitle: ", @QualificationJobTitle
#                 # puts
                    
                        
#             when "Employment Status"
#               @QualificationEmployment = false
#               @RFGEmployment = ''
              
#               (0..project.datapoints[m]["values"].length-1).each do |i|
#                 if (project.datapoints[m]["values"][i]["choice"] == 1) && (user.employment.to_i == 10) then
#                   @QualificationEmployment = true
#                   @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end 
#                 if (project.datapoints[m]["values"][i]["choice"] == 2) && (user.employment.to_i == 2) then
#                   @QualificationEmployment = true
#                   @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 3) && (user.employment.to_i == 1) then
#                   @QualificationEmployment = true
#                   @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 4) && (user.employment.to_i == 7)  then
#                   @QualificationEmployment = true
#                   @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 5) && (user.employment.to_i == 9)  then
#                   @QualificationEmployment = true
#                   @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#                 if (project.datapoints[m]["values"][i]["choice"] == 6) && ((user.employment.to_i == 3) || (user.employment.to_i == 4)) then
#                   @QualificationEmployment = true
#                   @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end                    
#                 if (project.datapoints[m]["values"][i]["choice"] == 7) && (user.employment.to_i == 8)  then
#                   @QualificationEmployment = true
#                   @RFGEmployment = project.datapoints[m]["values"][i]["choice"].to_s
#                 else
#                 end
#               end
#               # print "User entered Employment: ", user.employment
#               # puts
#               # print "Project qual Employment: ", project.datapoints[m]["values"]
#               # puts
#               # print "@QualificationEmployment: ", @QualificationEmployment
#               # puts
          
          
#           end # case statement
#         end # do m
        
        
#         print " QUALIFICATIONS CRITERIA for: ", project.rfg_id
#         puts
#         print "country = ", (project.country == "AU")
#         puts
#         print "cpi = ", (project.cpi > @currentpayoutstr)
#         puts        
#         print "Live = ", (project.projectStillLive)
#         puts
#         print "Age = ", (@QualificationAge)
#         puts
#         print "Gender = ", (@QualificationGender)
#         puts
#         print "Computer = ", (@QualificationComputer)
#         puts
#         print "Zip = ", (@QualificationZip)
#         puts
#         print "HHI = ", (@QualificationHhi)
#         puts
#         print "PIndustry = ", (@QualificationPindustry)
#         puts
#         print "Education = ", (@QualificationEducation)
#         puts
#         print "Employment = ", (@QualificationEmployment)
#         puts
#         print "JobTitle = ", (@QualificationJobTitle)
#         puts
#         print "Ethnicity = ", (@QualificationEthnicity)
#         puts
#         print "Children = ", (@QualificationChildren)
#         puts
        
         
#         if ( (project.country == "AU") && ( project.projectStillLive ) && (project.cpi > @currentpayoutstr) && ( @QualificationAge ) && ( @QualificationGender ) && (@QualificationComputer) && ( @QualificationZip ) && ( @QualificationHhi ) && ( @QualificationPindustry ) && ( @QualificationEducation ) && ( @QualificationEmployment ) && (@QualificationChildren) && (@QualificationJobTitle) && (@QualificationEthnicity) ) then
          
#           @RFGQualifiedProjects << project.rfg_id
          
#           print '********** In total USER_ID: ', user.user_id, ' has QUALIFIED for the following RFG projects: ', @RFGQualifiedProjects
#           puts
          

#           # Verify if there is a quota for the qualified user and if it is full
          
#           if project.quotas.length > 0 then 
#             # @RFGQuotaIsAvailable = false # initialize quota availability as false, then check quotas to prove/disprove
#            # @RFGQuotaFull = false
           
#             print "--------------------------------------------------------------->>>>>>>>> NUMBER OF QUOTAS = ", project.quotas.length
#             puts
            
#             (0..project.quotas.length-1).each do |j|
#               (0..project.quotas[j]["datapoints"].length-1).each do |n|
            
#               # Assume quota per qualifications is available. These are turned false if user does not qualify
#               @QualificationAge = true
#               @QualificationGender = true
#               @QualificationComputer = true
#               @QualificationZip = true
#               @QualificationHhi = true
#               @QualificationPindustry = true
#               @QualificationChildren = true
#               @QualificationEducation = true
#               @QualificationEmployment = true
                                        
#               case project.quotas[j]["datapoints"][n]["name"]
#               when "Age"
#                 #logic: once found true then turn to true
#                 @QualificationAge = false
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                   @QualificationAge = (project.quotas[j]["datapoints"][n]["values"][i]["min"]..project.quotas[j]["datapoints"][n]["values"][i]["max"]).include?(user.age.to_i) || @QualificationAge
#                 end
#                 print "User entered age: ", user.age
#                 puts
#                 print "Project quota age: ", project.quotas[j]["datapoints"][n]["values"]
#                 puts
#                 print "Quota for @QualificationAge: ", @QualificationAge
#                 puts
            
#               when "Gender"
#                 if project.quotas[j]["datapoints"][n]["values"].length == 2 then
#                   @QualificationGender = true
#                 else
#                   if project.quotas[j]["datapoints"][n]["values"][0]["choice"] == user.gender.to_i then
#                     @QualificationGender = true
#                   else
#                     @QualificationGender = false
#                   end
#                 end
#                 print "User entered gender: ", user.gender
#                 puts
#                 print "Project quota gender: ", project.quotas[j]["datapoints"][n]["values"]
#                 puts
#                 print "Quota for @QualificationGender: ", @QualificationGender
#                 puts
                
                
#               when "Computer Check"
#                 @QualificationComputer = false
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                  if ((((project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5)) && (@MS_is_mobile == '&MS_is_mobile=false')) || (((project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3)) && (@MS_is_mobile == '&MS_is_mobile=true'))) then 
#                    @QualificationComputer = true
#                  else
#                  end
#                 end
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>User computer type: ", @MS_is_mobile
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Project quota for computer types: ", project.quotas[j]["datapoints"][n]["values"]
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>@QualificationComputer: ", @QualificationComputer
#                 puts
                
                
            
#               # when "List of FSAs (AU)"
# #                 @QualificationZip = false
# #                 print "Project qual zip: ", project.quotas[j]["datapoints"][n]["values"]
# #                 puts
# #                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
# #                   if (project.quotas[j]["datapoints"][n]["values"][i]["freelist"]).include?(user.ZIP.slice(0..2)) then
# #                     @QualificationZip = true
# #                   else
# #                   end
# #                 end
# #                 print "User entered SLICED zip: ", user.ZIP.slice(0..2)
# #                 puts
# #
# #                 print "Quota for @QualificationZip: ", @QualificationZip
# #                 puts
            
#               when "Household Income"
#                 @QualificationHhi = false
#                 (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
                     
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && ( (user.householdincome.to_i == 1) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && ( (user.householdincome.to_i == 2) || (user.householdincome.to_i == 3) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && ( (user.householdincome.to_i == 4) || (user.householdincome.to_i == 5) || (user.householdincome.to_i == 6) || (user.householdincome.to_i == 7) || (user.householdincome.to_i == 8) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && ( (user.householdincome.to_i == 9) || (user.householdincome.to_i == 10) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && ( (user.householdincome.to_i == 11) || (user.householdincome.to_i == 12) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && ( (user.householdincome.to_i == 13) || (user.householdincome.to_i == 14) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && ( (user.householdincome.to_i == 15) || (user.householdincome.to_i == 16) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
              
#                   if ( (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 8) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 9) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 10) || (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 11) ) && ( (user.householdincome.to_i == 17) || (user.householdincome.to_i == 18) ) then
#                     @QualificationHhi = true                    
#                   else
#                   end
#                 end
#                 # print "User entered HHI: ", user.householdincome
#                 # puts
#                 # print "Project HHI quota: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 # print "Quota for @QualificationHhi: ", @QualificationHhi
#                 # puts
                  
                  
#                 when "Employment Industry"
#                   @QualificationPindustry = false
      
#                   (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|

#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && (user.pindustry.to_i == 1) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && (user.pindustry.to_i == 2) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && (user.pindustry.to_i == 3) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && (user.pindustry.to_i == 4) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 8) && (user.pindustry.to_i == 5) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 9) && (user.pindustry.to_i == 6) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 10) && (user.pindustry.to_i == 7) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 11) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 12) && (user.pindustry.to_i == 8) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 13) && (user.pindustry.to_i == 9) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 14) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 15) && (user.pindustry.to_i == 10) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 16) && (user.pindustry.to_i == 11) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 17) && (user.pindustry.to_i == 12) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 18) && (user.pindustry.to_i == 13) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 19) && (user.pindustry.to_i == 14) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 20) && (user.pindustry.to_i == 15) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 21) && (user.pindustry.to_i == 16) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 22) && (user.pindustry.to_i == 17) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 23) && (user.pindustry.to_i == 18) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 24) && (user.pindustry.to_i == 19) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 25) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 26) && (user.pindustry.to_i == 20) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 27) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 28) && (user.pindustry.to_i == 22) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 29) && (user.pindustry.to_i == 23) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 30) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 31) && (user.pindustry.to_i == 24) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 32) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 33) && (user.pindustry.to_i == 25) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 34) && (user.pindustry.to_i == 26) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 35) && (user.pindustry.to_i == 27) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 36) && (user.pindustry.to_i == 28) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 37) && (user.pindustry.to_i == 29) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 38) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 39) && (user.pindustry.to_i == 30) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 40) && (user.pindustry.to_i == 31) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 41) && (user.pindustry.to_i == 32) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 42) && (user.pindustry.to_i == 33) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 43) && (user.pindustry.to_i == 34) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 44) && (user.pindustry.to_i == 35) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 45) && (user.pindustry.to_i == 36) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 46) && (user.pindustry.to_i == 37) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 47) && (user.pindustry.to_i == 38) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 48) && (user.pindustry.to_i == 39) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 49) && (user.pindustry.to_i == 40) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 50) && (user.pindustry.to_i == 41) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 51) && (user.pindustry.to_i == 42) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 52) && (user.pindustry.to_i == 44) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 53) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 54) && (user.pindustry.to_i == 45) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 55) && (user.pindustry.to_i == 46) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 56) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 57) && (user.pindustry.to_i == 49) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 58) && (user.pindustry.to_i == 48) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 59) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 60) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 61) && (user.pindustry.to_i == 50) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 62) && ( (user.pindustry.to_i == 50) || (user.pindustry.to_i == 21) || (user.pindustry.to_i == 43) || (user.pindustry.to_i == 47) ) then
#                       @QualificationPindustry = true
#                     else
#                     end
              
#                     if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 63) && (user.pindustry.to_i == 51) then
#                       @QualificationPindustry = true
#                     else
#                     end                  
#                 end
#                 # print "User entered Pindustry: ", user.pindustry
#                 # puts
#                 # print "Project quota Pindustry: ", project.quotas[j]["datapoints"][n]["values"]
#                 # puts
#                 # print "Quota for @QualificationPindustry: ", @QualificationPindustry
#                 # puts
                  
#               when "Children"
#                 @QualificationChildren = false
#                 y=1
#                 if user.children.include?("-3105") then
#                   @QualificationChildren = false
#                 else
#                   (0..user.children.length-1).each do |c|
#                     (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                       if (project.quotas[j]["datapoints"][n]["values"][i]["unit"]!=nil) then
#                         if (project.quotas[j]["datapoints"][n]["values"][i]["unit"]==0) then 
#                           y=1
#                         else
#                           y=12
#                         end
#                       else
#                         y=1
#                       end
#                       @QualificationChildren = (((project.quotas[j]["datapoints"][n]["values"][i]["min"]..project.quotas[j]["datapoints"][n]["values"][i]["max"]).include?(((user.children[c].to_f/2).round)*y)) && ((project.quotas[j]["datapoints"][n]["values"][i]["gender"] == nil) || (user.children[c].to_i % 2==project.quotas[j]["datapoints"][n]["values"][i]["gender"].to_i % 2))) || @QualificationChildren
#                     end
#                   end
#                 end
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> User entered Children: ", user.children
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Project quota Children: ", project.quotas[j]["datapoints"][n]["values"]
#                 puts
#                 print "---------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Quota for @QualificationChildren: ", @QualificationChildren
#                 puts    
                
#               # when "Children Age and Gender"
# #                   @QualificationChildren = false
# #                   (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
# #                     if ((project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s & user.children).empty? == false) then
# #                       @QualificationChildren = true
# #                     else
# #                     end
# #                   end
# #                   # print "User entered Children: ", user.children
# #                   # puts
# #                   # print "Project quota Children: ", project.quotas[j]["datapoints"][n]["values"]
# #                   # puts
# #                   # print "@QualificationChildren: ", @QualificationChildren
# #                   # puts
                  
#               when "Education (AU)"
#                   @QualificationEducation = false
#                   (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && (user.eduation.to_i == 1) then
#                       @QualificationEducation = true
#                       @RFGEducationAU = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end 
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && ((user.eduation.to_i == 2) || (user.eduation.to_i == 3)) then
#                     @QualificationEducation = true
#                     @RFGEducationAU = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && (user.eduation.to_i == 4) then
#                     @QualificationEducation = true
#                     @RFGEducationAU = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && ((user.eduation.to_i == 5) || (user.eduation.to_i == 6))  then
#                     @QualificationEducation = true
#                     @RFGEducationAU = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && ((user.eduation.to_i == 7) || (user.eduation.to_i == 8))  then
#                     @QualificationEducation = true
#                     @RFGEducationAU = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && (user.eduation.to_i == 9) then
#                     @QualificationEducation = true
#                     @RFGEducationAU = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end                    
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && ((user.eduation.to_i == 10) || (user.eduation.to_i == 11))  then
#                     @QualificationEducation = true
#                     @RFGEducationAU = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                 end
#                       # print "User entered Education: ", user.eduation
#                       # puts
#                       # print "Project quota Education: ", project.quotas[j]["datapoints"][n]["values"]
#                       # puts
#                       # print "Quota for @QualificationEducation: ", @QualificationEducation
#                       # puts
                        
#                 when "Employment Status"
#                   @QualificationEmployment = false
#                   (0..project.quotas[j]["datapoints"][n]["values"].length-1).each do |i|
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 1) && (user.employment.to_i == 10) then
#                     @QualificationEmployment = true
#                     @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end 
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 2) && (user.employment.to_i == 2) then
#                     @QualificationEmployment = true
#                     @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 3) && (user.employment.to_i == 1) then
#                     @QualificationEmployment = true
#                     print "----------->>> project employment choice: ", project.quotas[j]["datapoints"][n]["values"][i]["choice"], 'and user.employment: ', user.employment
#                     puts 
#                     @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 4) && (user.employment.to_i == 7)  then
#                     @QualificationEmployment = true
#                     @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 5) && (user.employment.to_i == 9)  then
#                     @QualificationEmployment = true
#                     @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 6) && ((user.employment.to_i == 3) || (user.employment.to_i == 4)) then
#                     @QualificationEmployment = true
#                     @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end                    
#                   if (project.quotas[j]["datapoints"][n]["values"][i]["choice"] == 7) && (user.employment.to_i == 8)  then
#                     @QualificationEmployment = true
#                     @RFGEmployment = project.quotas[j]["datapoints"][n]["values"][i]["choice"].to_s
#                   else
#                   end
#                 end
#               # print "User entered Employment: ", user.employment
#               # puts
#               # print "Project quota Employment: ", project.quotas[j]["datapoints"][n]["values"]
#               # puts
#               # print "Quota for @QualificationEmployment: ", @QualificationEmployment
#               # puts
              
#               end # case
              




#               if project.quotas[j]["datapoints"][n]["completesLeft"] == nil then
#                 @QuotaCompletesLeft = true
#                 p "************* RFG CompletesLeft is UNDEFINED ***************"
#               else 
#                 if (project.quotas[j]["datapoints"][n]["completesLeft"] > 0) then
#                   @QuotaCompletesLeft = true
#                   p "************* RFG CompletesLeft is > 0  ***************"

#                 else
#                   @QuotaCompletesLeft = false
#                   p "************* RFG CompletesLeft is = 0  ***************"
#                 end
#               end






              
#               print " QUOTA AVAILABILITY CRITERIA for: ", project.rfg_id
#               puts
#               print "country = ", (project.country == "AU")
#               puts
#               print "Age = ", (@QualificationAge)
#               puts
#               print "Gender = ", (@QualificationGender)
#               puts
#               print "Computer = ", (@QualificationComputer)
#               puts
#               print "Zip = ", (@QualificationZip)
#               puts
#               print "HHI = ", (@QualificationHhi)
#               puts
#               print "PIndustry = ", (@QualificationPindustry)
#               puts
#               print "Education = ", (@QualificationEducation)
#               puts
#               print "Employment = ", (@QualificationEmployment)
#               puts
#               print "Children = ", (@QualificationChildren)
#               puts
#               print "CompletesLeft = ", (@QuotaCompletesLeft)
#               puts
                            
              
#               if ( (project.country == "AU") && ( @QualificationAge ) && ( @QualificationGender ) && (@QualificationComputer) && ( @QualificationZip ) && ( @QualificationHhi ) && ( @QualificationPindustry ) && ( @QualificationEducation ) && ( @QualificationEducation ) && (@QualificationEmployment) && (@QualificationChildren) && (@QuotaCompletesLeft) ) then
              
#                 @RFGQuotaIsAvailable = true
#                 puts "******* Quota is available"
#               else
#                 # if previous quota was available then preserve that fact
#                 @RFGQuotaIsAvailable = false || @RFGQuotaIsAvailable
#               end
              
#               end # reviewed all n nested qualifications of a quota
                           
#             end # all j quotas have been inspected

#           else            
#             print "************** Quota available: There are no quota restrictions"
#             puts
            
#             @RFGQuotaIsAvailable = true
            
#           end # quotaavailable?
          
#           if @RFGQuotaIsAvailable == true then
          
#             print '********** USER_ID: ', user.user_id, ' has Quota for the RFG project: ', project.rfg_id
#             puts
           
#             print "--------------*************** Checking for duplicate user fingerprint for project number: ", project.rfg_id
#             puts
                  
#             # lets assume the user is not a duplicate, typically
#             @duplicateFingerprint = false
        
#             if user.fingerprint != nil then
        
#               print "--------------->>>>>>******************* user fingerprint: ", user.fingerprint
#               puts
        
#               command = { :command => "livealert/duplicateCheck/1", :rfg_id => project.rfg_id, :fingerprint => user.fingerprint, :ip => user.ip_address }.to_json
                    
#               time=Time.now.to_i
#               hash = Digest::HMAC.hexdigest("#{time}#{command}", secret.scan(/../).map {|x| x.to_i(16).chr}.join, Digest::SHA1)
#               uri = URI("https://www.saysoforgood.com/API?apid=#{apid}&time=#{time}&hash=#{hash}")
            
#               begin
#                 Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
#                   req = Net::HTTP::Post.new uri
#                   req.body = command
#                   req.content_type = 'application/json'
#                   response = http.request req
#                   @RFGFingerprint = JSON.parse(response.body)  
#                 end
                    
#                 rescue Net::ReadTimeout => e  
#                 puts e.message
#               end
              
#               print "******************* Fingerprint 1, result: ", @RFGFingerprint, ' ', @RFGFingerprint["result"]
#               puts
                      
#               if ((@RFGFingerprint == nil) || (@RFGFingerprint["result"] != 0))  then
#                 @duplicateFingerprint = true            
#                 puts "----------->>>>>> @RFGFingerprint response returned by rfg server was not valid. User will not be allowed to enter, ZZZZZZZZ"
            
#               else
                        
#                 print "******************* Fingerprint 2, isDuplicate?: ", @RFGFingerprint, ' ', @RFGFingerprint["response"]["isDuplicate"]
#                 puts
                      
#                 if @RFGFingerprint["response"]["isDuplicate"] == true then
#                   @duplicateFingerprint = true
#                   puts "----------->>>>>> @RFGFingerprint response returned by rfg server was true. User will not be allowed to enter, XXXXXXXX"             
#                 else
#                   @duplicateFingerprint = false
#                   puts "----------->>>>>> @RFGFingerprint response returned by rfg server was false, User can enter VVVVVVVVVV"
#                 end
              
#               end      
                 
#             else
#               # Force it to be not duplicate because it had no fingerprint
#               @duplicateFingerprint = false          
#               puts "----------->>>>>> user fingerprint was nil. User can enter, CCCCCCCCC"
          
#             end # fingerprint == nil
            
#             if  @duplicateFingerprint == false then
                 
#               print "*************** This is not a duplicate user for this project. Add to list of projects for userride", project.rfg_id
#               puts
              
#               if (@RFGProjectsWithQuota.length == 0) then
#                 @RFGProjectsWithQuota << project.rfg_id
#                 @RFGSupplierLinks << project.link+'&rfg_id='+project.rfg_id
#               else
#                 @inserted = false
#                 (0..@RFGProjectsWithQuota.length-1).each do |i|
#                   @project1 = RfgProject.where('rfg_id = ?', @RFGProjectsWithQuota[i]).first
#                   if ( (project.estimatedIR > @project1.estimatedIR) && (@inserted == false) ) then
#                     @RFGProjectsWithQuota.insert(i, project.rfg_id)
#                     @RFGSupplierLinks.insert(i, project.link+'&rfg_id='+project.rfg_id)
#                     @inserted = true
#                   else
#                   end
#                 end
#               end
                        
#               if (@RFGProjectsWithQuota.uniq.length >= @RFG_AU) then
#                 @foundtopprojectswithquota = true
#               else  
#                 #do nothing
#               end             
              
#             else
            
#               print '-------------->>> DUPLICATE: Skip this project as User has already completed this project', project.rfg_id
#               puts
          
#             end # if @duplicateFingerprint
            
#           else
            
#             print '********** USER_ID: ', user.user_id, ' DOES NOT HAVE ANY Quota available for the RFG projects: ', project.rfg_id
#             puts
#           end # if quota available = true
          
#         else
          
#           print '************ User DID NOT QUALIFY for project number = ', project.rfg_id
#           puts
          
#         end # Qualification check

#         else
#         end # if projectStillLive
 
#       else
#       end # if foundtopprojects
      
#     end # do all projects
    
#     else
#     end # country = "5"
      
    
    
#     print '********** In total USER_ID: ', user.user_id, ' has Quota available for the RFG projects: ', @RFGProjectsWithQuota
#     puts
      
#     print '********** Total SUPPLIERLINKS for the RFG projects user has quota for, are: ', @RFGSupplierLinks
#     puts
      
      
    # Assemble additional parameters values to pass with the entry link
      
    # if user.children != nil then
#       if user.children.include?("-3105") then
#         @RFGchildrenvalue = '&ChildrenAgeGender=37&children=false'
#       else
#         @RFGchildrenvalue = '&children=true&ChildrenAgeGender='+user.children[0]
#         if user.children.length > 1 then
#           (1..user.children.length-1).each do |i|
#             @RFGchildrenvalue = @RFGchildrenvalue+'&ChildrenAgeGender='+user.children[i]
#           end
#         else
#         end
#       end
#     else
#       @RFGchildrenvalue = ''
#     end
        
    if user.age != nil then
      @RFGbirthday = (Time.now.year.to_i - user.age.to_i).to_s + "-" + Random.rand(12).to_s + "-" + Random.rand(30).to_s
      print "-----RFGbirthday-------------------***************__________________", @RFGbirthday
      puts
    else
      @RFGbirthday = ""
    end
     
    if user.employment == nil then
      @RFGEmployment = ''
    else
      case user.employment.to_i
      when 1
        @RFGEmployment = "3"
      when 2
        @RFGEmployment = "2"
      when 3
        @RFGEmployment = "6"
      when 4
        @RFGEmployment = "6"
      when 5
        @RFGEmployment = "3"
      when 6
        @RFGEmployment = "4"
      when 7
        @RFGEmployment = "4"      
      when 8
        @RFGEmployment = "7"
      when 9
        @RFGEmployment = "5"
      when 10
        @RFGEmployment = "1"
      when 11
        @RFGEmployment = "7"
      when 12
        @RFGEmployment = ""
      end
    end

    print "----RFGEmployment--------------------***************__________________", @RFGEmployment
    puts

    if user.eduation == nil then
      @RFGEducationUS = ''
      @RFGEducationCA = ""
      @RFGEducationAU = ""
    else
      if user.country=="9" then
        case user.eduation.to_i
        when 1
          @RFGEducationUS = "1"
        when 2
          @RFGEducationUS = "2"
        when 3
          @RFGEducationUS = "3"
        when 4
          @RFGEducationUS = "4"
        when 5
          @RFGEducationUS = "5"        
        when 6
          @RFGEducationUS = "6"
        when 7
          @RFGEducationUS = "7"
        when 8
          @RFGEducationUS = "7"
        when 9
          @RFGEducationUS = "7"
        when 10
          @RFGEducationUS = "7"
        when 11
          @RFGEducationUS = "8"
        when 12
          @RFGEducationUS = "9"
        end
      else
        if user.country=="6" then
          case user.eduation.to_i
          when 1
            @RFGEducationCA = "1"
          when 2
            @RFGEducationCA = "2"
          when 3
            @RFGEducationCA = "2"
          when 4
            @RFGEducationCA = "3"
          when 5
            @RFGEducationCA = "4"        
          when 6
            @RFGEducationCA = "4"
          when 7
            @RFGEducationCA = "5"
          when 8
            @RFGEducationCA = "5"
          when 9
            @RFGEducationCA = "6"
          when 10
            @RFGEducationCA = "7"
          when 11
            @RFGEducationCA = "7"
          when 12
            @RFGEducationCA = ""
          end
        else
          if user.country=="5" then
            case user.eduation.to_i
            when 1
              @RFGEducationAU = "1"
            when 2
              @RFGEducationAU = "2"
            when 3
              @RFGEducationAU = "2"
            when 4
              @RFGEducationAU = "3"
            when 5
              @RFGEducationAU = "4"        
            when 6
              @RFGEducationAU = "4"
            when 7
              @RFGEducationAU = "5"
            when 8
              @RFGEducationAU = "5"
            when 9
              @RFGEducationAU = "6"
            when 10
              @RFGEducationAU = "7"
            when 11
              @RFGEducationAU = "7"
            when 12
              @RFGEducationAU = ""
            end
          else
          end
        end
      end
    end  
      
    print "----RFGEducation-US, CA, AU -------------------***************__________________", @RFGEducationUS, @RFGEducationCA, @RFGEducationAU
    puts 
    
    if (user.race == nil && user.country==9) then
      @RFGEthnicity = ''
    else
      case user.race.to_i
      when 1
        @RFGEthnicity = "3"
      when 2
        @RFGEthnicity = "1"
      when 3
        @RFGEthnicity = "6"
      when 4
        @RFGEthnicity = "2"
      when 5
        @RFGEthnicity = "2"        
      when 6
        @RFGEthnicity = "2"
      when 7
        @RFGEthnicity = "2"
      when 8
        @RFGEthnicity = "2"
      when 9
        @RFGEthnicity = "2"
      when 10
        @RFGEthnicity = "2"
      when 11
        @RFGEthnicity = "4"
      when 12
        @RFGEthnicity = "4"
      when 13
        @RFGEthnicity = "4"
      when 14
        @RFGEthnicity = "4"
      when 15
        @RFGEthnicity = ""
      when 16
        @RFGEthnicity = "7"
      end

      if user.ethnicity == nil then
        #do nothing
      else
        case user.ethnicity.to_i
        when 2
          @RFGEthnicity = "5"
        when 3
          @RFGEthnicity = "5"
        when 4
          @RFGEthnicity = "5"
        when 5
          @RFGEthnicity = "5"        
        when 6
          @RFGEthnicity = "5"
        when 7
          @RFGEthnicity = "5"
        when 8
          @RFGEthnicity = "5"
        when 9
          @RFGEthnicity = "5"
        when 10
          @RFGEthnicity = "5"
        when 11
          @RFGEthnicity = "5"
        when 12
          @RFGEthnicity = "5"
        when 13
          @RFGEthnicity = "5"
        when 14
          @RFGEthnicity = "5"
        end
      end
    end 
    
    print "----RFGEthnicity--------------------***************__________________", @RFGEthnicity
    puts

    if user.householdincome == nil then
      @RFGHhi = ''
    else
      if user.country=="9" then
        case user.householdincome.to_i
        when 1
          @RFGHhi = "1"
        when 2
          @RFGHhi = "1"
        when 3
          @RFGHhi = "1"
        when 4
          @RFGHhi = "2"
        when 5
          @RFGHhi = "2"        
        when 6
          @RFGHhi = "3"
        when 7
          @RFGHhi = "3"
        when 8
          @RFGHhi = "3"
        when 9
          @RFGHhi = "3"
        when 10
          @RFGHhi = "3"
        when 11
          @RFGHhi = "4"
        when 12
          @RFGHhi = "4"
        when 13
          @RFGHhi = "4"
        when 14
          @RFGHhi = "4"
        when 15
          @RFGHhi = "4"
        when 16
          @RFGHhi = "5"
        when 17
          @RFGHhi = "5"
        when 18
          @RFGHhi = "5"
        when 19
          @RFGHhi = "5"
        when 20
          @RFGHhi = "5"
        when 21
          @RFGHhi = "6"
        when 22
          @RFGHhi = "6"
        when 23
          @RFGHhi = "7"
        when 24
          @RFGHhi = "7"
        when 25
          @RFGHhi = "8"
        when 26
          @RFGHhi = "9"
        when 27
          @RFGHhi = "12"
        end
      else
        if user.country=="6" then
          case user.householdincome.to_i
          when 1
            @RFGHhi = "1"
          when 2
            @RFGHhi = "2"
          when 3
            @RFGHhi = "2"
          when 4
            @RFGHhi = "3"
          when 5
            @RFGHhi = "3"        
          when 6
            @RFGHhi = "3"
          when 7
            @RFGHhi = "3"
          when 8
            @RFGHhi = "3"
          when 9
            @RFGHhi = "4"
          when 10
            @RFGHhi = "4"
          when 11
            @RFGHhi = "5"
          when 12
            @RFGHhi = "5"
          when 13
            @RFGHhi = "6"
          when 14
            @RFGHhi = "6"
          when 15
            @RFGHhi = "7"
          when 16
            @RFGHhi = "7"
          when 17
            @RFGHhi = "8"
          when 18
            @RFGHhi = "12"
          end          
        else
          if user.country=="5" then
            case user.householdincome.to_i
            when 1
              @RFGHhi = "1"
            when 2
              @RFGHhi = "2"
            when 3
              @RFGHhi = "3"
            when 4
              @RFGHhi = "4"
            when 5
              @RFGHhi = "5"        
            when 6
              @RFGHhi = "6"
            when 7
              @RFGHhi = "7"
            when 8
              @RFGHhi = "8"
            when 9
              @RFGHhi = "9"
            when 10
              @RFGHhi = "9"
            when 11
              @RFGHhi = "10"
            when 12
              @RFGHhi = "10"
            when 13
              @RFGHhi = "11"
            when 14
              @RFGHhi = "11"
            when 15
              @RFGHhi = "12"
            when 16
              @RFGHhi = "12"
            when 17
              @RFGHhi = "13"
            when 18
              @RFGHhi = "14"
            end
          else
          end
        end
      end
    end 
    
    print "----RFGHhi -------------------***************__________________", @RFGHhi
    puts 

    if user.jobtitle == nil then
      @RFGJobTitle = ''
    else
      case user.jobtitle.to_i
      when 1
        @RFGJobTitle = "2"
      when 2
        @RFGJobTitle = "3"
      when 3
        @RFGJobTitle = "3"
      when 4
        @RFGJobTitle = "4"
      when 5
        @RFGJobTitle = "5"        
      when 6
        @RFGJobTitle = "5"
      when 7
        @RFGJobTitle = "12"
      when 8
        @RFGJobTitle = "14"
      when 9
        @RFGJobTitle = "16"
      when 10
        @RFGJobTitle = "16"
      when 11
        @RFGJobTitle = "23"
      end
    end
    
    print "----RFGJobTitle -------------------***************__________________", @RFGJobTitle
    puts 

    if user.pindustry == nil then
      @RFGPindustry = ''
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

    print "----RFGPindustry -------------------***************__________________", @RFGPindustry
    puts
      
    if user.country=="9" then 
      @RFGAdditionalValues = '&rid='+@rid+'&country=US'+'&postalCode='+user.ZIP+'&gender='+user.gender+'&householdIncome='+@RFGHhi+'&employment='+@RFGEmployment+'&educationUS='+@RFGEducationUS+'&ethnicityUS='+@RFGEthnicity+'&jobTitle='+@RFGJobTitle+'&employmentIndustry='+@RFGPindustry+'&birthday='+@RFGbirthday
    else
      if user.country=="6" then
          @RFGAdditionalValues = '&rid='+@rid+'&country=CA'+'&postalCode='+user.ZIP+'&gender='+user.gender+'&educationCA='+@RFGEducationCA+'&householdIncome='+@RFGHhi+'&employment='+@RFGEmployment+'&jobTitle='+@RFGJobTitle+'&employmentIndustry='+@RFGPindustry+'&birthday='+@RFGbirthday
      else
        if user.country=="5" then
            @RFGAdditionalValues = '&rid='+@rid+'&country=AU'+'&postalCode='+user.ZIP+'&gender='+user.gender+'&educationAU='+@RFGEducationAU+'&householdIncome='+@RFGHhi+'&employment='+@RFGEmployment+'&jobTitle='+@RFGJobTitle+'&employmentIndustry='+@RFGPindustry+'&birthday='+@RFGbirthday
        else
        end
      end
    end    
      
    # if @parsed_user_agent.platform == 'iPhone' then
      
    #   @MS_is_mobile = '&MS_is_mobile=true'
    #   p "*************************************** RankRFGProjects: MS_is_mobile is set TRUE"
      
    # else
    #   @MS_is_mobile = '&MS_is_mobile=false'
    #   p "*************************************** RankRFGProjects: MS_is_mobile is set FALSE"
      
    # end
      
    # if @RFGSupplierLinks.length > 0 then
    #   (0..@RFGSupplierLinks.length-1).each do |i|
    #     @RFGSupplierLinks[i] = @RFGSupplierLinks[i]+@RFGAdditionalValues+@MS_is_mobile
    #   end
    #   print "--------------************>>>>>>>>>>>>>>>>>>> RFGSupplierLinks List <<<<<<<<<<<<<<<<<<<*********************-----------------: ", @RFGSupplierLinks
    #   puts
    # else
    #   # do nothing, no RFG surveys match the user
    #   puts "************ User did not match any available quota in RFG projects"
    # end   
















    # Instead of LiveLink use Offerwall surveys

















    p "--------------------**************>>>>>>>>>>>>>> RFG Offerwall API call with params <<<<<<<<<<<<<<<<<*****************-------------------"

    if user.country=="9" then
      command = { :command => "offerwall/query/1", :rid => @rid, :country => "US", :fingerprint => user.fingerprint, :ip => user.ip_address, :postalCode => user.ZIP, :gender => user.gender, :birthday => @RFGbirthday, :householdIncome => @RFGHhi, :employment => @RFGEmployment, :educationUS => @RFGEducationUS, :ethnicityUS => @RFGEthnicity, :jobTitle => @RFGJobTitle, :employmentIndustry => @RFGPindustry}.to_json
    else
      if user.country=="6" then
        command = { :command => "offerwall/query/1", :rid => @rid, :country => "CA", :fingerprint => user.fingerprint, :ip => user.ip_address, :postalCode => user.ZIP, :gender => user.gender, :birthday => @RFGbirthday, :householdIncome => @RFGHhi, :educationCA => @RFGEducationCA, :employment => @RFGEmployment, :jobTitle => @RFGJobTitle, :employmentIndustry => @RFGPindustry}.to_json
      else
        if user.country=="5" then
      command = { :command => "offerwall/query/1", :rid => @rid, :country => "AU", :fingerprint => user.fingerprint, :ip => user.ip_address, :postalCode => user.ZIP, :gender => user.gender, :birthday => @RFGbirthday, :householdIncome => @RFGHhi, :educationAU => @RFGEducationAU, :employment => @RFGEmployment, :jobTitle => @RFGJobTitle, :employmentIndustry => @RFGPindustry}.to_json          
        else
        end
      end
    end




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
      print "*********No surveys reurned bu RFG Offerwall**********"
      puts
      @RFGSupplierLinks = []
    else
    
      @maxIR = @OfferwallResponse["response"]["surveys"][0]["ir"]
      @RFGOfferwallSupplierLink = @OfferwallResponse["response"]["surveys"][0]["offer_url"]

      @NumberOfSurveys = @OfferwallResponse["response"]["surveys"].length
        
      print "************ Number of surveys on RFG Offerwall: ", @NumberOfSurveys
      puts

      (0..@NumberOfSurveys-1).each do |i|

        if @maxIR < @OfferwallResponse["response"]["surveys"][i]["ir"] then
          @maxIRIndex = i
          @maxIR = @OfferwallResponse["response"]["surveys"][i]["ir"]
          @RFGOfferwallSupplierLink = @OfferwallResponse["response"]["surveys"][i]["offer_url"]
        else
        end
      end
      
      print "RFG Offerwall SupplierLink: ", @RFGOfferwallSupplierLink, " at index: ", @maxIRIndex, " with IR: ", @maxIR
      puts

      @RFGSupplierLinks = []
      @RFGSupplierLinks << @RFGOfferwallSupplierLink+@RFGAdditionalValues

      print "************>>>>User will be sent to this RFG link>>>>>>>>>>>>>>>>>>>>>>>>>0000ooooooooppppppp ", @RFGSupplierLinks,  "***************************************************************"
      puts
    
    end










    
    else
    # do nothing for RFG
    end # RFG status is ACTIVE / OFF
    
    # print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++a ", user.user_id, " of ", user.country, " Time-4 End RFG selection: ", Time.now
    # puts
    
    # Begin the ride next
    userride (session_id)      
        
  end #selectRfgProjects




  def selectInnovateSurveys (session_id)

    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    @INVSupplierLink << "http://innovate.go2cloud.org/aff_c?offer_id=821&aff_id=273&source=273&aff_sub="+"4444"+user.user_id

  end





       
  def userride (session_id)
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
    
    user = User.find_by session_id: session_id
    @PID = user.user_id

    # If user is blacklisted, then qterm
    if user.black_listed == true then
      print '******************** Userride: UserID is BLACKLISTED: ', user.user_id
      puts
      tracker.track(user.ip_address, 'NS_BL')
      redirect_to '/users/nosuccess'
      return
    else
    end
       
    # # Order FED, ADHOC and RFG surveys
    
    # if (@RFGIsBack) then
    #   puts "RFG is Back"
    #   if user.SupplierLink == nil then
    #     # No FED surveys
    #     if @adhocSupplierLinks == nil then
    #       user.SupplierLink = @RFGSupplierLinks
    #       puts "RFG is Back-1 but no ADHOC or FED surveys are available"
    #     else
    #       user.SupplierLink = @adhocSupplierLinks
    #       user.SupplierLink = user.SupplierLink + @RFGSupplierLinks
    #       puts "RFG is Back-2"
    #     end
    #   else      
    #     if @adhocSupplierLinks == nil then
    #       user.SupplierLink = user.SupplierLink + @RFGSupplierLinks
    #       puts "RFG is Back-3"
    #     else
    #       @tmp1 = user.SupplierLink + @adhocSupplierLinks
    #       user.SupplierLink = @tmp1 + @RFGSupplierLinks
    #       puts "RFG is Back-4"
    #     end
    #   end
    # else
    #   if (@RFGIsFront) then
    #     puts "RFG is Front"
    #     if user.SupplierLink == nil then
    #       # No FED surveys
    #       if @adhocSupplierLinks == nil then
    #         user.SupplierLink = @RFGSupplierLinks
    #         puts "RFG is Front-1"
    #       else
    #         user.SupplierLink = @adhocSupplierLinks
    #         user.SupplierLink = user.SupplierLink + @RFGSupplierLinks
    #         puts "RFG is Front-2"
    #       end
    #     else
    #       if @RFGSupplierLinks == nil then
    #         if @adhocSupplierLinks == nil then
    #           puts "RFG is Front-3 but no RFG or ADHOC surveys available"
    #         else
    #           @tmp2 = user.SupplierLink
    #           #user.SupplierLink = @tmp2 + @adhocSupplierLinks
    #           user.SupplierLink = @adhocSupplierLinks + @tmp2
    #           puts "RFG is Front-4 but no RFG surveys available"
    #         end

    #       else
    #         if @adhocSupplierLinks == nil then
    #           @tmp3 = user.SupplierLink
    #           user.SupplierLink = @RFGSupplierLinks + @tmp3
    #           puts "RFG is Front-5"
    #         else
    #           @tmp4 = @adhocSupplierLinks + @RFGSupplierLinks
    #           @tmp5 = user.SupplierLink
    #           user.SupplierLink = @tmp4 + @tmp5
    #           puts "RFG is Front-6"
    #         end
    #       end
    #     end
    #   else
    #     puts "*************** RFG is not included *********"
    #     if @adhocSupplierLinks == nil then
    #       # do nothing, only FED surveys are available
    #       puts "RFG not Included-1"
    #     else
    #       @tmp6 = user.SupplierLink
    #       user.SupplierLink = @tmp6 + @adhocSupplierLinks
    #       puts "RFG not Included-2"
    #     end
    #   end
    # end
    
    # # Save the order of FED, ADHOC and RFG
    
    # user.save
    




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
      
      @p2sSupplierLink = 'http://www.your-surveys.com/?si=55&ssi='+@SUBID+'&'+@p2s_AdditionalValues+'&hmac='+@hmac
      
      print "**************P2S SupplierLink = ", @p2sSupplierLink
      puts
      
      user.SupplierLink << @p2sSupplierLink

      # Save the list of SupplierLinks with P2S, if ACTIVE
    
      user.save

    else
      puts "-------------------********************** P2S is not attached ********************------------------------"
    end #if P2SisAttached 

    





    # Order surveys by stackOrder for the user ride

    case @net.stackOrder
    when "AFRP"
      user.SupplierLink = @adhocSupplierLinks + @fedSupplierLinks + @RFGSupplierLinks + [@p2sSupplierLink]
      #user.SupplierLink << @p2sSupplierLink
      print "************ AFRP user will be sent to these surveys: ", user.SupplierLink
      puts

    when "ARFP"
      user.SupplierLink = @adhocSupplierLinks + @RFGSupplierLinks + @fedSupplierLinks + [@p2sSupplierLink]
      print "************ ARFP user will be sent to these surveys: ", user.SupplierLink
      puts

    when "FARP"
      user.SupplierLink = @fedSupplierLinks + @adhocSupplierLinks + @RFGSupplierLinks + [@p2sSupplierLink]
      print "************ FARP user will be sent to these surveys: ", user.SupplierLink
      puts

    when "FRAP"
      user.SupplierLink = @fedSupplierLinks + @RFGSupplierLinks + @adhocSupplierLinks + [@p2sSupplierLink]
      print "************ FRAP user will be sent to these surveys: ", user.SupplierLink
      puts

    when "RAFP"
      user.SupplierLink = @RFGSupplierLinks + @adhocSupplierLinks + @fedSupplierLinks + [@p2sSupplierLink]
      print "************ RAFP user will be sent to these surveys: ", user.SupplierLink
      puts

    when "RFAP"
      user.SupplierLink = @RFGSupplierLinks + @fedSupplierLinks + @adhocSupplierLinks + [@p2sSupplierLink]
      print "************ RFAP user will be sent to these surveys: ", user.SupplierLink
      puts

    when "RFP"
      user.SupplierLink = @RFGSupplierLinks + @fedSupplierLinks + [@p2sSupplierLink]
      print "************ RFP user will be sent to these surveys: ", user.SupplierLink
      puts

    when "FRP"
      user.SupplierLink = @fedSupplierLinks + @RFGSupplierLinks + [@p2sSupplierLink]
      print "************ FRP user will be sent to these surveys : ", user.SupplierLink
      puts
    end
    
    # Remove any blank entries
    if user.SupplierLink !=nil then
      user.SupplierLink.reject! { |c| c == nil}
    else
    end

    print "************ After removing blank entries, user will be sent to these surveys: ", user.SupplierLink
    puts








    # Start the user ride
    
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
    end # if user.SupplierLink == nil    
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
      user.SurveysAttempted << @adhocSurveyNumber
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
          @RadiumOnePostBack = HTTParty.post('http://panel.gwallet.com/network-node/postback/ketsciinc?sid='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
         rescue HTTParty::Error => e
           puts 'HttParty::Error '+ e.message
          retry
        end while @RadiumOnePostBack.code != 200
      else
      end  

      if user.netid == "IS1oti09bgaHqaTIxr67lj9fmAQ" then

        begin
          puts "************************* TEST SENDING RADIUMONE3 POSTBACK **************************************"
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
    
      user.SurveysAttempted << 'TESTSURVEY'
      user.SurveysCompleted[user.user_id] = [Time.now, 'TESTSURVEY', user.clickid, @net_name]
      #user.SurveysCompleted[user.user_id] = [Time.now, 'TESTSURVEY', user.clickid, user.netid.slice(0..2)]
      user.save
    
    end # duplicate is false
    
    if user.netid == "Gd7a7dAkkL333frcsLA21aaH" then
      redirect_to '/users/successfulMML'
    else
      redirect_to '/users/successful'
    end  
  end # p3action

end