class UsersController < ApplicationController

require 'httparty'

require 'mixpanel-ruby'

  def new
    
    # Parse incoming click URL e.g. http://localhost:3000/users/new?NID=Aiuy56420xzLL7862rtwsxcAHxsdhjkl&CID=333333
#   @netid = params[:NID]
#    @clickid = params[:CID]
#    p 'netid=', @netid
#    p 'clickid', @clickid
    
#    @user = User.new
  end

  def show
#    case params[:status]
#      when '2'
#        redirect_to '/users/qterm'
#      when '3'
#        redirect_to '/users/24hrsquotaexceeded'
#      when '4'
#        # for debugging
#        remote_ip = request.remote_ip
#        hdr = env['HTTP_USER_AGENT']
#        sid = session.id
#        render json: 'ip address: '+remote_ip+' UserAgent: '+hdr+' session id: '+sid
#    end
  end
  
  def create
  end

  def eval_age

    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    
  # calculate age for COPA eligibility

@age=params[:age]

#    @age = age( params[:user][:birth_month], params[:user][:birth_date], params[:user][:birth_year] )  
#    print 'Age works out to be', @age
#    puts
    if @age.to_i<13 then
      p '********************* Entered age is < 13'
      # should be replaced by call to userride
#      redirect_to 'http://www.ketsci.com/redirects/status?status=3'
      redirect_to '/users/nosuccess'
    else  
      # Enter the user with the following credentials in our system or find user's record  
      ip_address = request.remote_ip
      session_id = session.id
      netid = params[:netid]
      clickid = params[:clickid]
      
      tracker.track(@ip_address, 'Age')
      
# Change this to include validating a cookie first(more unique compared to IP address id) before verifying by IP address      
      if ((User.where(ip_address: ip_address).exists?) && (User.where(session_id: session.id).exists?)) then
        first_time_user=false
#        p '********* EVAL_AGE: USER EXISTS'
      else
        first_time_user=true
#        p 'EVAL_AGE: USER DOES NOT EXIST'
      end

      if (first_time_user) then
        # Create a new-user record
        p '****************** EVAL_AGE: Creating new record for FIRST TIME USER'
#        @user = User.new(user_params)
        @user = User.new
        @user.age = @age
        @user.netid = netid
        @user.clickid = clickid
#       @user.payout = should be extracted from advertiser id in call
        # Initialize user ride related lists. These protect from getting old lists, if the user restarts taking surveys in the same session after a long break. However, these get a blank entry on the list due to save action
        @user.QualifiedSurveys = []
        @user.SurveysWithMatchingQuota = []
        @user.SupplierLink = []
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
    
      if (first_time_user==false) then
        user = User.where("ip_address = ? AND session_id = ?", ip_address, session_id).first
        # user = User.where( "ip_address = ip_address AND session_id = session.id" )

        #NTS: Why do I have to stop at first. Optimizes. But there should be not more than 1 entry.
        p user
        if user.black_listed==true then
          userride (session_id)
#          redirect_to 'http://www.ketsci.com/redirects/qterm'
        else
          p '******************* EVAL_AGE: Modifying existing record of a REPEAT USER'
#          user.birth_date=params[:user][:birth_date]
#          user.birth_month=params[:user][:birth_month]
#          user.birth_year=params[:user][:birth_year]    
          user.age = @age
          user.netid = netid
          user.clickid = clickid
          # These get a blank entry on the list due to save action
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
#    print 'TOS: User found in TOS:', user
#    puts
    user.tos=true
#    user.save
#    redirect_to '/users/qq2'

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
    
    user=User.find_by session_id: session.id

    if params[:gender] != nil
      user.gender=params[:gender]
      user.save
      redirect_to '/users/tq1'
    else
      redirect_to '/users/qq2'
    end
    
  end
  
  def trap_question_1
    user=User.find_by session_id: session.id
    user.trap_question_1_response=params[:color]
    if params[:color]=="Green" then
      user.save
      redirect_to '/users/qq3'
    else
#      redirect_to '/users/show'
      user.watch_listed=true
      user.save
      # Flash user to pay attention
      flash[:alert] = "Please pay more attention to your responses!"
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
          flash[:alert] = "Please pay more attention to your responses!"
          redirect_to '/users/tq2b'
        end
      else
        user.save
        # Flash user to pay attention
        flash[:alert] = "Please pay more attention to your responses!"
        redirect_to '/users/tq2b'
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
             redirect_to '/users/nosuccess'
          end
        end
      end
    end
  end
  
  def zip_US

    user=User.find_by session_id: session.id
    user.ZIP=params[:zip]
    user.save
#    redirect_to '/users/qq5_US'
    ranksurveysforuser(session.id)
  end
  
  def zip_CA

    user=User.find_by session_id: session.id
    user.ZIP=params[:zip]
    user.save
#    redirect_to '/users/qq5_CA'
    ranksurveysforuser(session.id)
  end
  
  def zip_IN

    user=User.find_by session_id: session.id
    user.ZIP=params[:zip]
    user.save
#    redirect_to '/users/qq5_IN'
    ranksurveysforuser(session.id)
  end
  
  def zip_AU

    user=User.find_by session_id: session.id
    user.ZIP=params[:zip]
    user.save
#    redirect_to '/users/qq7_AU'
    ranksurveysforuser(session.id)
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
  
#  def householdincome

#    user=User.find_by session_id: session.id
#    user.householdincome=params[:hhi]
#    user.save
#    redirect_to '/users/show'
#  end
  
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
  
  def education_AU

    user=User.find_by session_id: session.id
    user.eduation=params[:education]
    user.save
    redirect_to '/users/qq8_AU'
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
  
  def householdincome_AU  

    user=User.find_by session_id: session.id
    user.householdincome=params[:hhi]
    user.save
    redirect_to '/users/qq9'
  end
  
  def householdcomp  

    user=User.find_by session_id: session.id
#    user.householdcomp=params[:householdcomp][:range]
    user.householdcomp=params[:householdcomp]
    user.save
    ranksurveysforuser(session.id)
#    redirect_to '/users/show'
  end

  def ranksurveysforuser (session_id)

    user=User.find_by session_id: session_id
    if user.gender == '1' then
      @GenderPreCode = [ "1" ]
    else
      @GenderPreCode = [ "2" ]
    end
    
    # Just in case user goes back to last qualification question and returns - this prevents the array from adding duplicates to previous list. Need to prevent back action across the board and then delete these to avaoid blank entries in these arrays.
    user.QualifiedSurveys = []
    user.SurveysWithMatchingQuota = []
    user.SupplierLink = []

      # Lets find surveys that user is qualified for.
      
      # If this is a TEST e.g. with a network provider then route user to run the standard test survey.
      @netid = user.netid
#      print '@netid', @netid
#      puts
      if Network.where(netid: @netid).exists? then
        net = Network.find_by netid: @netid
#        print 'net =', net
#        puts
        if (net.status == "EXTTEST") then
          case (net.testcompletes.length)
            when 0..9
              net.testcompletes[user.clickid] = [1]
              redirect_to '/users/techtrendssamplesurvey'
              return
            when 10..100000000
              puts "*************************** More than 10 EXTTEST attempts"
              redirect_to '/users/testattemptsmaxd'
              return
          end
        else
          if (net.status == "INACTIVE") then
            redirect_to '/users/nosuccess'
            return
          else
            if (net.status == "INTTEST") then
              @netstatus = "INTTEST"
            else
              # MUST BE AN ACTIVE NETWORK -> Continue
            end
          end
        end
      else
        # Bad netid, Network is not known
        p '****************************** TEST NETWORK: BAD NETWOK'
        redirect_to '/users/nosuccess'
        return
      end
      
    puts "STARTING SEARCH FOR SURVEYS USER QUALIFIES FOR"
    # change countrylanguageid setting to match user countryID only
    @usercountry = (user.country).to_i
#    print '*************** RANKSURVEYS FOR USER: User country is =', @usercountry
#    puts

#    Survey.where("CountryLanguageID = 5 OR CountryLanguageID = 9 OR CountryLanguageID = 8").order( "SurveyGrossRank" ).each do |survey|

if (Survey.where("CountryLanguageID = ?", @usercountry)).exists? then
  # do nothing
#  print 'Surveys with the users LanguageID are available', user.user_id
#  puts
else
  p '******************** USERRIDE: No Surveys with country language found in users_controller'
  redirect_to '/users/nosuccess'
  return
#  @NoSurveysForThisCountryLanguage = true
#  user.QualifiedSurveys == nil
#  userride(session_id)
end


      Survey.where("CountryLanguageID = ?", @usercountry).order( "SurveyGrossRank" ).each do |survey|

      if ((( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([ user.age ] & survey.QualificationAgePreCodes.flatten) == [ user.age ] )) && (( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (@GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode ) && (( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || ([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ] ) && ( survey.SurveyStillLive ) && ((survey.CPI == nil) || (survey.CPI > 2.15))) then
        
# Add more generic condition that survey.CPI > user.payout by network
        
        #Prints for testing code
          
 #       ans0 = ( survey.try(:QualificationGenderPreCodes) )
        ans1 = ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (( @GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )
        ans2 = ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([user.age] & survey.QualificationAgePreCodes.flatten) == [user.age])
        ans3 = ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
#        print 'BEGIN: USER QUALIFIED FOR SURVEY NUMBER =', survey.SurveyNumber, 'RANK=', survey.SurveyGrossRank, 'Gender from Survey=', survey.QualificationGenderPreCodes, 'User enetered Gender: ', @GenderPreCode, 'USER ENTERED AGE=', user.age, 'AGE PreCodes from Survey=', survey.QualificationAgePreCodes, 'User Entered ZIP:', user.ZIP, 'ZIP PreCodes from Survey:', survey.QualificationZIPPreCodes
#        puts
#        print 'Ans1 - Gender match:', ans1, 'Ans2 - Age match:', ans2, 'Ans3 - ZIP match:', ans3
#        puts
        
        user.QualifiedSurveys << survey.SurveyNumber
        
      else
        # This survey qualifications did not match with the user
        # Print for testing/verification
        ans4 = ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (( @GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )
        ans5 = ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([user.age] & survey.QualificationAgePreCodes.flatten) == [user.age])
        ans6 = ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
#        print 'END: USER DID NOT QUALIFY FOR THIS SURVEY', survey.SurveyNumber
#        puts
#        print 'Ans4 - Gender match:', ans4, 'Ans5 - Age match:', ans5, 'Ans6 - ZIP match:', ans6
#        puts
      end
      # End of all surveys in the database that meet the country, age, gender and ZIP criteria
    end

    if user.QualifiedSurveys.empty? then
      puts 'User did not qualify for a survey so taking user to show FailureLink page'
      userride (session_id)
    else
#      print 'IN TOTAL USER HAS QUALIFIED FOR the following surveys= ', user.user_id, user.QualifiedSurveys
#      puts
      
      # delete the empty item from initialization
  #    user.QualifiedSurveys.reject! { |c| c.empty? }
      
      print 'IN TOTAL USER HAS QUALIFIED FOR the following surveys (without Blanks)= ', user.user_id, user.QualifiedSurveys
      puts

      # Lets save the surveys user qualifies for in this user's record of database in rank order
      user.save

      # Look through surveys this user is qualified for to check if there is quota available
        
      (0..user.QualifiedSurveys.length-1).each do |j|
        @surveynumber = user.QualifiedSurveys[j]
 #       survey = Survey.where( "SurveyNumber = ?", @surveynumber )
        Survey.where( "SurveyNumber = ?", @surveynumber ).each do |survey|

        @NumberOfQuotas = survey.SurveyQuotas.length-1
#        print 'NumberofQuotas:', @NumberOfQuotas+1
#        puts

        (0..@NumberOfQuotas).each do |k|
          @NumberOfRespondents = survey.SurveyQuotas[k]["NumberOfRespondents"]
          @SurveyQuotaCPI = survey.SurveyQuotas[k]["QuotaCPI"]
#          print 'NumberofRespondents:', @NumberOfRespondents, 'QuotaCPI:', @SurveyQuotaCPI
#          puts
#          print survey.SurveyQuotas[k]["Questions"]
#          puts
        
          if (survey.SurveyQuotas[k]["Questions"] == nil ) then
            # Quota is open for all users so add this survey number to user's ride
            puts 'Quota is open for all users'
            user.SurveysWithMatchingQuota << @surveynumber
          else
            # check if a quota exists for this user by matching precodes for all questions in the quota
            # Assume all quotas are available unless proven false
            
            agequotaexists=true
            genderquotaexists=true
            @ZIPquotaexists=true
            
            (0..survey.SurveyQuotas[k]["Questions"].length-1).each do |l|
#              print 'Looping through quotas=', l  
#              puts
              case survey.SurveyQuotas[k]["Questions"][l]["QuestionID"]
                
                when 42
#                  print 'Age:', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
#                  puts
                  if ([ user.age ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.age ] ) then
                    agequotaexists=true
 #                   puts 'Age question matches'
                  else
                    agequotaexists=false
  #                  puts 'Age question does not match'
                  end
                when 43
#                  puts 'Gender:', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                  if ( @GenderPreCode & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == @GenderPreCode ) then
                    genderquotaexists=true
#                    puts 'Gender question matches'
                  else
                    genderquotaexists=false
#                    puts 'Gender question does not match'
                  end
                  
                when 45
#                  print 'ZIPS', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
#                  puts
 
                # Except for Canada, check for zip in other countries

                  if ((user.country == 6) || ( [ user.ZIP ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ZIP ] )) then
                    @ZIPquotaexists=true
#                   puts 'ZIP question matches'
                  else
                    @ZIPquotaexists=false
#                    puts 'ZIP question does not match'
                  end
                  # End case
                end
                # End l
              end  
                  # Quota k exists if qualifications for user profile match
                  if ((survey.SurveyQuotas[k]["NumberOfRespondents"] <= 0 ) || (agequotaexists == false) || (genderquotaexists == false) || (@ZIPquotaexists == false)) then
            #        puts 'This overall quota did not match the user'
                  else
             #       puts 'This overall quota matches what we know about the user and there are completes needed for the quota'
#                   @tmp << @surveynumber
                    user.SurveysWithMatchingQuota << @surveynumber
                    # End if
                  end                    
              # End if
            end        
            #End k
          end
          # End where
        end
        # End j
      end
        # End 'if' user did qualify for survey(s)
    end
    
      # Lets save the survey numbers that the user meets the quota requirements for in this user's record of database in rank order
      
      user.SurveysWithMatchingQuota = user.SurveysWithMatchingQuota.uniq
      print 'List of (unique) surveys where quota is available:', user.SurveysWithMatchingQuota
      puts
      
      # removing the blank entry
#      if user.SurveysWithMatchingQuota !=nil then
#        user.SurveysWithMatchingQuota.reject(&:empty?)
#      else
#      end
      
#      print 'List of (unique AND without Blanks) surveys where quota is available: ', user.SurveysWithMatchingQuota
#      puts

# *********** REMOVE AFTER TESTING      
#      @tmp_SurveysWithMatchingQuota = []
#      (0..user.SurveysWithMatchingQuota.length-1).each do |i|
#        if user.SurveysWithMatchingQuota[i].to_i > 67821 then
#          @tmp_SurveysWithMatchingQuota << user.SurveysWithMatchingQuota[i]
#        else
#          p 'Skipping this survey due to no SupplierLink', user.SurveysWithMatchingQuota[i]
#        end
#      end
#      user.SurveysWithMatchingQuota = @tmp_SurveysWithMatchingQuota
#      puts 'REDUCED List of (unique) surveys where SupplierLink is available:', user.SurveysWithMatchingQuota
# UPTO HERE      
      
      user.save
      
      # Begin the ride
      userride (session_id)
      
     # End matching surveys to users and ranking 
  end
    
  def userride (session_id)
    
    user = User.find_by session_id: session_id
    @PID = user.user_id

    # If user is blacklisted, then qterm
    if user.black_listed == true then
#      redirect_to 'https://www.ketsci.com/redirects/status?status=5'+'&PID='+@PID
    redirect_to '/users/nosuccess'
    return
    else
    end
    
    # The user does not qualify for any survey in the inventory, from the begining. (Failure/Terminate)
    if ((user.QualifiedSurveys.empty?) || (user.SurveysWithMatchingQuota.empty?)) then
      p '******************** USERRIDE: No Surveys matching quals/quota were found in users_controller'
#      redirect_to 'https://www.ketsci.com/redirects/status?status=3'+'&PID='+@PID
      redirect_to '/users/nosuccess'
      return
    else
    end
    
     # If the user qualifies for one or more survey, redirect to the top ranked survey and repeat until success/failure/OT/QT
    (0..user.SurveysWithMatchingQuota.length-1).each do |i|
      @surveynumber = user.SurveysWithMatchingQuota[i]
      Survey.where( "SurveyNumber = ?", @surveynumber ).each do |survey|
        # Change from test to live link
        user.SupplierLink[i] = survey.SupplierLink["LiveLink"]
      end
    end
    
#    print 'USER HAS QUOTA FOR SUPPLIERLINKS =', user.SupplierLink
 #   puts
    
    # removing the blank entry
    if user.SupplierLink !=nil then
      user.SupplierLink.reject! { |c| c.empty? }
    else
    end
    
    print 'USER HAS QUOTA FOR SUPPLIERLINKS (without blanks!) = ', user.SupplierLink
    puts
    
    # Save the list of SupplierLinks in user record
    user.save

    # Start the ride
    if (@netstatus == "INTTEST") then
      @PID = 'test'
    else
      @PID = user.user_id
    end
    
    if user.country=="9" then 
      @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&ZIP='+user.ZIP
    else
      if user.country=="6" then
        @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&ZIP_Canada='+user.ZIP
      else
        if user.country=="5" then
          @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&Fulcrum_ZIP_AU='+user.ZIP
        else
          if user.country=="7" then
            @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&Fulcrum_ZIP_IN='+user.ZIP
          else
            puts "*************************************** UseRide: Find out why country code is not correctly set"
            @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender
            return
          end
        end
      end
    end
    

# Append user profile parameters like AGE, GENDER, etc, before sending user to Fulcrum (Does not help since are nagating between the surveys?)

# **** For testing (with PID preset to test in TestLink)
#    p '*******USERRIDE: User will be sent to this survey:', user.SupplierLink[0]
#   remove this survey from the list in case the user returns back in the same session after OQ, Failure, or after claiming reward to retry
#    @EntryLink = user.SupplierLink[0]
#    user.SupplierLink = user.SupplierLink.drop(1)
#    user.save
#    redirect_to @EntryLink
# ***** until here
  
# Alternate hardcoded test link in case navigation fails  
# redirect_to 'http://staging.samplicio.us/router/default.aspx?SID=8c047e4e-bf66-4014-bbb6-8b3fd6ebc3ac&FIRID=MSDHONI7&SUMSTAT=1&PID=test'

# ****** Uncomment for launch
#   remove this survey from the list in case the user returns back in the same session after OQ, Failure, to retry in same session
    print 'User will be sent to this survey: ', user.SupplierLink[0]+@PID+@AdditionalValues
    puts
    @EntryLink = user.SupplierLink[0]+@PID+@AdditionalValues
    user.SupplierLink = user.SupplierLink.drop(1)
    user.save
    redirect_to @EntryLink
# *** until here
  end
  
#  def age(dob_month, dob_date, dob_year)
#    dob = (dob_date +'-'+ dob_month +'-'+ dob_year).to_date
#    p 'dob', dob
#    now = Time.now.utc.to_date
#    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
#  end

  # Sample survey pages control logic (p0 to success)
  
  def p1action
    redirect_to '/users/p2'
  end
  
  def p2action
    redirect_to '/users/p3'
  end
  
  def p3action
    session_id = session.id
    user = User.find_by session_id: session_id
    print 'CID=', user.clickid
    puts
    begin
      @FyberPostBack = HTTParty.post('http://www2.balao.de/SPM4u?transaction_id='+user.clickid, :headers => { 'Content-Type' => 'application/json' })
        rescue HTTParty::Error => e
        puts 'HttParty::Error '+ e.message
        retry
    end while @FyberPostBack.code != 200
    
    user.SurveysCompleted["TESTSURVEY"] = [0, 'TESTSURVEY', user.clickid, user.netid]
    user.save
    
    redirect_to '/users/successful'
  end
    
#  private
#    def user_params
#      params.require(:user).permit(:age)
#      params.require(:user).permit(:age, :birth_date, :birth_month, :birth_year)
#    end

end