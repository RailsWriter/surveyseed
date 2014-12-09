class UsersController < ApplicationController
  def new
    @user = User.new        
  end

  def show
    case params[:status]
      when '1'
        redirect_to '/users/failure'
      when '2'
        redirect_to '/users/qterm'
      when '3'
        redirect_to '/users/24hrsquotaexceeded'
      when '4'
        # for debugging
        remote_ip = request.remote_ip
        hdr = env['HTTP_USER_AGENT']
        sid = session.id
        render json: 'ip address: '+remote_ip+' UserAgent: '+hdr+' session id: '+sid
    end
  end
  
  def create
  end

  def eval_age
  # calculate age for COPA eligibility
    @age = age( params[:user][:birth_month], params[:user][:birth_date], params[:user][:birth_year] )  
    p 'Age works out to be', @age
    if @age<13 then
      p 'Entered age is < 13'
      # should be replaced by call to userride
      redirect_to 'http://www.ketsci.com/redirects/status?status=3'
    else  
      # Enter the user in our system or find user's record      
      ip_address = request.remote_ip
      session_id = session.id

# Change this to include validating a cookie first(more unique compared to IP address id) before verifying by IP address      
      if ((User.where(ip_address: ip_address).exists?) && (User.where(session_id: session.id).exists?)) then
        first_time_user=false
        p 'EVAL_AGE: USER EXISTS'
      else
        first_time_user=true
        p 'EVAL_AGE: USER DOES NOT EXIST'
      end

      if (first_time_user) then
        # Create a new-user record
        p 'EVALAGE: FIRST TIME USER'
        @user = User.new(user_params)
        @user.age = @age.to_s
#        @user.age = (Time.zone.now.year-@user.birth_year).to_s
        # Get the advertiser id to determine payout value
#       @user.payout = should be extracted from advertiser id in call
        # Initialize user ride related lists. These protect from getting old lists, if the user restarts taking surveys in the same session after a long break. However, these get a blank entry on the list due to save action       
        @user.QualifiedSurveys = 
        @user.SurveysWithMatchingQuota = []
        @user.SupplierLink = []
        @user.user_agent = env['HTTP_USER_AGENT']
        @user.session_id = session_id
#        @user.user_id = SecureRandom.hex(16)
        @user.user_id = SecureRandom.urlsafe_base64
        @user.ip_address = ip_address
        @user.tos = false
        @user.number_of_attempts_in_last_24hrs=1
        @user.watch_listed=false
        @user.black_listed=false
        @user.attempts_time_stamps_array = [Time.now]
        @user.save
        p @user
        redirect_to '/users/tos'
      else
      end
    
      if (first_time_user==false) then
        user = User.where("ip_address = ? AND session_id = ?", ip_address, session_id).first
#        user = User.where( "ip_address = ip_address AND session_id = session.id" )

        #NTS: Why do I have to stop at first. Optimizes. But there should be not more than 1 entry.
        p user
        if user.black_listed==true then
          userride (session_id)
#          redirect_to 'http://www.ketsci.com/redirects/qterm'
        else
          p 'EVAL_AGE: REPEAT USER'
          user.birth_date=params[:user][:birth_date]
          user.birth_month=params[:user][:birth_month]
          user.birth_year=params[:user][:birth_year]    
          user.age = @age.to_s 
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
      
    user=User.find_by session_id: session.id
    p user
    user.tos=true

    # Update number of attempts in last 24 hrs record of the user
    if ( user.number_of_attempts_in_last_24hrs==nil ) then
      user.number_of_attempts_in_last_24hrs=user.attempts_time_stamps_array.count { |x| x > (Time.utc.now-1.day) }
    else
    end
    
    user.save
    
    if ( user.attempts_time_stamps_array.length==1 ) then
      p 'FIRST TIME USER'
      redirect_to '/users/qq2'
    else
    
      # set 24 hr survey attempts in separate sessions from same device/IP address here
      if (user.number_of_attempts_in_last_24hrs < 50) then
        p 'A REPEAT USER'
        # skip gender and other demo questions due to responses in last 24 hrs
        redirect_to '/users/qq9'
      else
        # user has made too many attempts to take surveys
        redirect_to '/users/24hrsquotaexceeded'
      end
    end
      
    # set 24 hr survey completes quota here
#    if (user.SurveysCompleted[count { |x| x > (Time.now-1.day) } == 5) then
#       p 'Exceeded quota of surveys to fill for today'
#       redirect_to '/users/24hrsquotaexceeded'
#     else
#     end
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
          # send to quality term the user
          userride (session_id)
        else
          user.watch_listed=true
          user.save
          # Flash user to pay attention
          flash[:alert] = "Please pay more attention to your responses!"
        end
      else
        user.save
        # Flash user to pay attention
        flash[:alert] = "Please pay more attention to your responses!"
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
    ranksurveysforuser(session.id)
#    redirect_to '/users/show'
  end

  def ranksurveysforuser (session_id)

    user=User.find_by session_id: session_id
    if user.gender == 'Male' then
      @GenderPreCode = [ "1" ]
    else
      @GenderPreCode = [ "2" ]
    end
    
    # Just in case user goes back to last qualification question and returns - this prevents the array from adding duplicates to previous list. Need to prevent back action across the board and then delete these to avaoid blank entries in these arrays.
    user.QualifiedSurveys = []
    user.SurveysWithMatchingQuota = []
    user.SupplierLink = []

      # Surveys that user is qualified for
# change countrylanguageid setting
      
    puts "STARTING SEARCH FOR SURVEYS USER QUALIFIES FOR"

    Survey.where("CountryLanguageID = 5 OR CountryLanguageID = 9 OR CountryLanguageID = 8").order( "SurveyGrossRank" ).each do |survey|
      if ((( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([ user.age ] & survey.QualificationAgePreCodes.flatten) == [ user.age ] )) && (( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (@GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode ) && (( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || ([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ] ) && ( survey.SurveyStillLive )) then
        
# Add condition that survey.CPI > user.payout
        
        #Prints for testing code
          
        ans0 = ( survey.try(:QualificationGenderPreCodes) )
        ans1 = ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (( @GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )
        ans2 = ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([user.age] & survey.QualificationAgePreCodes.flatten) == [user.age])
        ans3 = ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
        puts 'BEGIN: USER QUALIFIED FOR SURVEY NUMBER =', survey.SurveyNumber, 'RANK=', survey.SurveyGrossRank, 'Gender from Survey=', survey.QualificationGenderPreCodes, 'User enetered Gender: ', @GenderPreCode, 'USER ENTERED AGE=', user.age, 'AGE PreCodes from Survey=', survey.QualificationAgePreCodes, 'User Entered ZIP:', user.ZIP, 'ZIP PreCodes from Survey:', survey.QualificationZIPPreCodes
        puts 'Ans1 - Gender match:', ans1, 'Ans2 - Age match:', ans2, 'Ans3 - ZIP match:', ans3
        
        user.QualifiedSurveys << survey.SurveyNumber
        
      else
        # This survey qualifications did not match with the user
        # Print for testing/verification
        ans4 = ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (( @GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )
        ans5 = ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([user.age] & survey.QualificationAgePreCodes.flatten) == [user.age])
        ans6 = ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
        puts 'END: USER DID NOT QUALIFY FOR THIS SURVEY', survey.SurveyNumber
        puts 'Ans4 - Gender match:', ans4, 'Ans5 - Age match:', ans5, 'Ans6 - ZIP match:', ans6
      end
      # End of all surveys in the database that meet the country, age, gender and ZIP criteria
    end

    if user.QualifiedSurveys == [] then
      puts 'You did not qualify for a survey so taking you to show FailureLink page'
      userride (session_id)
    else
      # delete the empty item from initialization
 #     @tmp = user.QualifiedSurveys.flatten.compact
 #    user.QualifiedSurveys = @tmp
      puts 'IN TOTAL USER HAS QUALIFIED FOR the following surveys=', user.QualifiedSurveys

      # Lets save the surveys user qualifies for in this user's record of database in rank order
      user.save

      # Look through surveys this user is qualified for to check if there is quota available
        
      (0..user.QualifiedSurveys.length-1).each do |j|
        @surveynumber = user.QualifiedSurveys[j]
 #       survey = Survey.where( "SurveyNumber = ?", @surveynumber )
        Survey.where( "SurveyNumber = ?", @surveynumber ).each do |survey|

        @NumberOfQuotas = survey.SurveyQuotas.length-1
        puts 'NumberofQuotas:', @NumberOfQuotas+1

        (0..@NumberOfQuotas).each do |k|
          @NumberOfRespondents = survey.SurveyQuotas[k]["NumberOfRespondents"]
          @SurveyQuotaCPI = survey.SurveyQuotas[k]["QuotaCPI"]
          puts 'NumberofRespondents:', @NumberOfRespondents, 'QuotaCPI:', @SurveyQuotaCPI
          puts survey.SurveyQuotas[k]["Questions"]
        
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
              puts 'l=', l  
              case survey.SurveyQuotas[k]["Questions"][l]["QuestionID"]
                
                when 42
                  puts '42:', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                  if ([ user.age ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.age ] ) then
                    agequotaexists=true
                    puts 'Age question matches'
                  else
                    agequotaexists=false
                    puts 'Age question does not match'
                  end
                when 43
                  puts '43:', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                  
                  if ( @GenderPreCode & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == @GenderPreCode ) then
                    genderquotaexists=true
                    puts 'Gender question matches'
                  else
                    genderquotaexists=false
                    puts 'Gender question does not match'
                  end
                  
                when 45
                  puts '45', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                  
                  if ([ user.ZIP ] & survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes").flatten == [ user.ZIP ] ) then
                    @ZIPquotaexists=true
                    puts 'ZIP question matches'
                  else
                    @ZIPquotaexists=false
                    puts 'ZIP question does not match'
                  end
                  # End case
                end
                # End l
              end  
                  # Quota k exists if qualifications for user profile match
                  if ((agequotaexists == false) || (genderquotaexists == false) || (@ZIPquotaexists == false)) then
                    puts 'This overall quota did not match the user'
                  else
                    puts 'This overall quota matches what we know about the user'
#                    @tmp << @surveynumber
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
      puts 'List of (unique) surveys where quota is available:', user.SurveysWithMatchingQuota

# *********** REMOVE AFTER TESTING      
      @tmp_SurveysWithMatchingQuota = []
      (0..user.SurveysWithMatchingQuota.length-1).each do |i|
        if user.SurveysWithMatchingQuota[i].to_i > 76793 then
          @tmp_SurveysWithMatchingQuota << user.SurveysWithMatchingQuota[i]
        else
          p 'Skipping this survey due to no SupplierLink', user.SurveysWithMatchingQuota[i]
        end
      end
      user.SurveysWithMatchingQuota = @tmp_SurveysWithMatchingQuota
      puts 'REDUCED List of (unique) surveys where SupplierLink is available:', user.SurveysWithMatchingQuota
# UPTO HERE      
      
      user.save
      
      # Begin the ride
      userride (session_id)
      
     # End matching surveys to users and ranking 
  end
    
  def userride (session_id)
    
    user = User.find_by session_id: session_id
    
    @PID = user.user_id

    # If user is blacklisted, qterm
    if user.black_listed == true then
      redirects_to 'https://www.ketsci.com/redirects/status?status=5'+'&PID='+@PID
    else
    end
    
    # The user does not qualify for any survey in the inventory, from the begining. (Failure/Terminate)
    if ((user.QualifiedSurveys == nil) || (user.SurveysWithMatchingQuota == nil)) then
      p 'No Surveys with matching quota found in users_controller'
      redirect_to 'https://www.ketsci.com/redirects/status?status=3'+'&PID='+@PID
    else
    end
    
     # If the user qualifies for one or more survey, redirect to the top ranked survey and repeat until success/failure/OT/QT
    (0..user.SurveysWithMatchingQuota.length-1).each do |i|
      @surveynumber = user.SurveysWithMatchingQuota[i]
      Survey.where( "SurveyNumber = ?", @surveynumber ).each do |survey|
# Change from test to live link
         user.SupplierLink[i] = survey.SupplierLink["TestLink"]
      end
    end
    
    puts 'USER HAS QUOTA FOR SUPPLIERLINKS =', user.SupplierLink
     
    # Save the list of SupplierLinks in user record
    user.save

    # Start the ride
    @PID = user.user_id   

# Append user profile parameters like AGE, GENDER, etc, before sending user to Fulcrum (Does not help since are nagating between the surveys?)

# **** For testing (with PID preset to test in TestLink)
    p 'User will be sent to this survey:', user.SupplierLink[0]
#   remove this survey from the list in case the user returns back in the same session after OQ, Failure, or after claiming reward to retry
    @EntryLink = user.SupplierLink[0]
    user.SupplierLink = user.SupplierLink.drop(1)
    user.save
    redirect_to @EntryLink
# ***** until here
  
# Alternate hardcoded test link in case navigation fails  
# redirect_to 'http://staging.samplicio.us/router/default.aspx?SID=8c047e4e-bf66-4014-bbb6-8b3fd6ebc3ac&FIRID=MSDHONI7&SUMSTAT=1&PID=test'

# ****** Uncomment for launch
#    p 'User will be sent to this survey:', user.SupplierLink[0]+@PID
#   remove this survey from the list in case the user returns back in the same session after OQ, Failure, or after claiming reward to retry
#    @EntryLink = user.SupplierLink[0]+@PID
#    user.SupplierLink = user.SupplierLink.drop(1)
#    user.save
#    redirect_to @EntryLink
# *** until here
  end
  
  def age(dob_month, dob_date, dob_year)
    
    dob = (dob_date +'-'+ dob_month +'-'+ dob_year).to_date
#    p 'dob', dob
    now = Time.now.utc.to_date
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end
    
  private
    def user_params
      params.require(:user).permit(:birth_date, :birth_month, :birth_year)
    end

end