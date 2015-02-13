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
    
      if (first_time_user==false) then
        user = User.where("ip_address = ? AND session_id = ?", ip_address, session_id).first
        p user

        # user = User.where( "ip_address = ip_address AND session_id = session.id" )
        # Why do I have to stop at first. Optimizes. But there should be not more than 1 entry.

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
      user.ZIP=params[:zip]
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
    user.race=params[:race].to_s
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
    
#    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
#    tracker.track(user.ip_address, 'hhi_US')
    
    if params[:hhi] != nil
      user.householdincome=params[:hhi]
      user.save
      redirect_to '/users/qq5_US'
    else
      redirect_to '/users/qq8_US'
    end
    
  end

  def householdincome_CA
    
#    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
#     tracker.track(user.ip_address, 'hhi_CA')
    
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
    
#    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
#     tracker.track(user.ip_address, 'hhi_AU')
    
    if params[:hhi] != nil
      user.householdincome=params[:hhi]
      user.save      
      redirect_to '/users/qq10'
    else
      redirect_to '/users/qq8_AU'
    end
    
  end
  
#  def householdcomp  

#    user=User.find_by session_id: session.id
###    user.householdcomp=params[:householdcomp][:range]
#    user.householdcomp=params[:householdcomp]
#    user.save
#    ranksurveysforuser(session.id)
#  end
  
  
  def employment  
    
    # Rename 'householdcomp' User records field to Employment
    
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

    user=User.find_by session_id: session.id
    
    tracker.track(user.ip_address, 'employment')    
    
    if params[:employment] != nil
      user.householdcomp=params[:employment]
      user.save
      ranksurveysforuser(session.id)
    else
      redirect_to '/users/qq10'
    end
    
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
      @poorconversion=false
      
      if Network.where(netid: @netid).exists? then
        net = Network.find_by netid: @netid
        user.currentpayout = net.payout
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
      
    puts "STARTING SEARCH FOR SURVEYS USER QUALIFIES FOR"
    # change countrylanguageid setting to match user countryID only
    @usercountry = (user.country).to_i


    if (Survey.where("CountryLanguageID = ?", @usercountry)).exists? then
      # do nothing
      #  print 'Surveys with the users LanguageID are available', user.user_id
      #  puts
    else
      p '******************** USERRIDE: No Surveys with country language found in users_controller'
      redirect_to '/users/nosuccess'
      return
    end


    if @poorconversion then
      @topofstack = 1
    else
      # make top of Custom surveys as starting spot for picking qualified surveys
      @topofstack = 96
    end

    print "**************************** PoorConversion is turned: ", @poorconversion, ' Topofstack is: ', @topofstack
    puts

    Survey.where("CountryLanguageID = ? AND SurveyGrossRank >= ?", @usercountry, @topofstack).order( "SurveyGrossRank" ).each do |survey|

#      Survey.where("CountryLanguageID = ?", @usercountry).order( "SurveyGrossRank" ).each do |survey|

      print "************************** Chosen survey rank: ", survey.SurveyGrossRank

      if (( survey.SurveyStillLive ) && 
        (( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([ user.age ] & survey.QualificationAgePreCodes.flatten) == [ user.age ] )) && 
        (( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || ((@GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )) && 
        (( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])) &&
        (( survey.QualificationRacePreCodes.empty? ) || ( survey.QualificationRacePreCodes.flatten == [ "ALL" ] ) || (([ user.race ] & survey.QualificationRacePreCodes.flatten) == [ user.race ])) &&
        (( survey.QualificationEthnicityPreCodes.empty? ) || ( survey.QualificationEthnicityPreCodes.flatten == [ "ALL" ] ) || (([ user.ethnicity ] & survey.QualificationEthnicityPreCodes.flatten) == [ user.ethnicity ])) &&
        (( survey.QualificationEducationPreCodes.empty? ) || ( survey.QualificationEducationPreCodes.flatten == [ "ALL" ] ) || (([ user.eduation ] & survey.QualificationEducationPreCodes.flatten) == [ user.eduation ])) &&
        (( survey.QualificationHHIPreCodes.empty? ) || ( survey.QualificationHHIPreCodes.flatten == [ "ALL" ] ) || (([ user.householdincome ] & survey.QualificationHHIPreCodes.flatten) == [ user.householdincome ])) &&
        (( survey.QualificationHHCPreCodes.empty? ) || ( survey.QualificationHHCPreCodes.flatten == [ "ALL" ] ) || (([ user.householdcomp.to_s ] & survey.QualificationHHCPreCodes.flatten) == [ user.householdcomp.to_s ])) &&
        ((survey.CPI == nil) || (survey.CPI > 0.99))) then
        
        # Add a more generic condition that survey.CPI > user.currentpayout
        
        #Prints for testing code

        @_gender = ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (( @GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )
        @_age = ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([user.age] & survey.QualificationAgePreCodes.flatten) == [user.age])
        @_ZIP = ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
        @_race = (( survey.QualificationRacePreCodes.empty? ) || ( survey.QualificationRacePreCodes.flatten == [ "ALL" ] ) || (([ user.race ] & survey.QualificationRacePreCodes.flatten) == [ user.race ]))
        @_ethnicity= (( survey.QualificationEthnicityPreCodes.empty? ) || ( survey.QualificationEthnicityPreCodes.flatten == [ "ALL" ] ) || (([ user.ethnicity ] & survey.QualificationEthnicityPreCodes.flatten) == [ user.ethnicity ]))
        @_education= (( survey.QualificationEducationPreCodes.empty? ) || ( survey.QualificationEducationPreCodes.flatten == [ "ALL" ] ) || (([ user.eduation ] & survey.QualificationEducationPreCodes.flatten) == [ user.eduation ]))
        @_HHI= (( survey.QualificationHHIPreCodes.empty? ) || ( survey.QualificationHHIPreCodes.flatten == [ "ALL" ] ) || (([ user.householdincome ] & survey.QualificationHHIPreCodes.flatten) == [ user.householdincome ]))
        @_employment = (( survey.QualificationHHCPreCodes.empty? ) || ( survey.QualificationHHCPreCodes.flatten == [ "ALL" ] ) || (([ user.householdcomp.to_s ] & survey.QualificationHHCPreCodes.flatten) == [ user.householdcomp.to_s ]))
        
        
        print '************ User QUALIFIED for survey number = ', survey.SurveyNumber, ' RANK= ', survey.SurveyGrossRank, ' User enetered Gender: ', @GenderPreCode, ' Gender from Survey= ', survey.QualificationGenderPreCodes, ' USER ENTERED AGE= ', user.age, ' AGE PreCodes from Survey= ', survey.QualificationAgePreCodes, ' User Entered ZIP: ', user.ZIP, ' ZIP PreCodes from Survey: ', survey.QualificationZIPPreCodes, ' User Entered Race: ', user.race, ' Race PreCode from survey: ', survey.QualificationRacePreCodes, ' User Entered ethnicity: ', user.ethnicity, ' Ethnicity PreCode from survey: ', survey.QualificationEthnicityPreCodes, ' User Entered education: ', user.eduation, ' Education PreCode from survey: ', survey.QualificationEducationPreCodes, ' User Entered HHI: ', user.householdincome, ' HHI PreCode from survey: ', survey.QualificationHHIPreCodes, ' User Entered Employment: ', user.householdcomp.to_s, ' Std_Employment PreCode from survey: ', survey.QualificationHHCPreCodes, 'SurveyStillAlive: ', survey.SurveyStillLive
         
        puts
        
        print 'Gender match: ', @_gender, ' Age match: ', @_age, ' ZIP match: ', @_ZIP, ' Race match: ', @_race, ' Ethnicity match: ', @_ethnicity, ' Education match: ', @_education, ' HHI match: ', @_HHI, ' Employment match: ', @_employment
        puts
        
        user.QualifiedSurveys << survey.SurveyNumber
        
      else
        # This survey qualifications did not match with the user
        # Print for testing/verification
        
        @_gender = ( survey.QualificationGenderPreCodes.flatten == [ "ALL" ] ) || (( @GenderPreCode & survey.QualificationGenderPreCodes.flatten) == @GenderPreCode )
        @_age = ( survey.QualificationAgePreCodes.flatten == [ "ALL" ] ) || (([user.age] & survey.QualificationAgePreCodes.flatten) == [user.age])
        @_ZIP = ( survey.QualificationZIPPreCodes.flatten == [ "ALL" ] ) || (([ user.ZIP ] & survey.QualificationZIPPreCodes.flatten) == [ user.ZIP ])
        @_race = (( survey.QualificationRacePreCodes.empty? ) || ( survey.QualificationRacePreCodes.flatten == [ "ALL" ] ) || (([ user.race ] & survey.QualificationRacePreCodes.flatten) == [ user.race ]))
        @_ethnicity = (( survey.QualificationEthnicityPreCodes.empty? ) || ( survey.QualificationEthnicityPreCodes.flatten == [ "ALL" ] ) || (([ user.ethnicity ] & survey.QualificationEthnicityPreCodes.flatten) == [ user.ethnicity ]))
        @_education = (( survey.QualificationEducationPreCodes.empty? ) || ( survey.QualificationEducationPreCodes.flatten == [ "ALL" ] ) || (([ user.eduation ] & survey.QualificationEducationPreCodes.flatten) == [ user.eduation ]))
        @_HHI= (( survey.QualificationHHIPreCodes.empty? ) || ( survey.QualificationHHIPreCodes.flatten == [ "ALL" ] ) || (([ user.householdincome ] & survey.QualificationHHIPreCodes.flatten) == [ user.householdincome ]))
        @_employment = (( survey.QualificationHHCPreCodes.empty? ) || ( survey.QualificationHHCPreCodes.flatten == [ "ALL" ] ) || (([ user.householdcomp.to_s ] & survey.QualificationHHCPreCodes.flatten) == [ user.householdcomp.to_s ]))
        
        
        print '************ User DID NOT QUALIFY for survey number = ', survey.SurveyNumber, ' RANK= ', survey.SurveyGrossRank, ' User enetered Gender: ', @GenderPreCode, ' Gender from Survey= ', survey.QualificationGenderPreCodes, ' USER ENTERED AGE= ', user.age, ' AGE PreCodes from Survey= ', survey.QualificationAgePreCodes, ' User Entered ZIP: ', user.ZIP, ' ZIP PreCodes from Survey: ', survey.QualificationZIPPreCodes, ' User Entered Race: ', user.race, ' Race PreCode from survey: ', survey.QualificationRacePreCodes, ' User Entered ethnicity: ', user.ethnicity, ' Ethnicity PreCode from survey: ', survey.QualificationEthnicityPreCodes, ' User Entered education: ', user.eduation, ' Education PreCode from survey: ', survey.QualificationEducationPreCodes, ' User Entered HHI: ', user.householdincome, ' HHI PreCode from survey: ', survey.QualificationHHIPreCodes, ' User Entered Employment: ', user.householdcomp.to_s, ' Std_Employment PreCode from survey: ', survey.QualificationHHCPreCodes, 'SurveyStillAlive: ', survey.SurveyStillLive
         
        puts
        
        print 'Gender match:', @_gender, ' Age match: ', @_age, ' ZIP match: ', @_ZIP, ' Race match: ', @_race, ' Ethnicity match: ', @_ethnicity, ' Education match: ', @_education, ' HHI match: ', @_HHI, ' Employment match: ', @_employment
        puts

      end
      # End of all surveys in the database that meet the country, age, gender and ZIP criteria
    end

    if user.QualifiedSurveys.empty? then  #0
      puts '************* User did not qualify for a survey so taking user to show FailureLink page'
      redirect_to '/users/nosuccess'
      return
#      userride (session_id)
    else #0
      
      # delete the empty item from initialization
  #    user.QualifiedSurveys.reject! { |c| c.empty? }
      
      print '********** This USER_ID has QUALIFIED for the following surveys: ', user.user_id, ' ', user.QualifiedSurveys
      puts

      # Lets save the surveys user qualifies for in this user's record of database in rank order
      user.save

      # Look through surveys this user is qualified for to check if there is quota available. Quota numbers can be read as Maximum or upper limit allowed for a qualification e.g. ages 20-24 quota of 30 and ages 25-30 quota of 50 is the upper limit on both of the groups. The code should first find if the number of respondents in the quota teh respondent falls in has need for more respondents. When a quota is split into parts then respondent must fall into at least one of them.
      
      
      puts "********************* STARTING To SEARCH if QUOTA is available for this user in the surveys user is Qualified. Stop after first 10 top ranked surveys with quota are found"
      
      @foundtopsurveyswithquota = false   # false means not finished finding top surveys (set it to true if testing p2s)
      
      (0..user.QualifiedSurveys.length-1).each do |j| #1
          
        if @foundtopsurveyswithquota == false then       #3 false means not finished finding top surveys

          @surveynumber = user.QualifiedSurveys[j]
          Survey.where( "SurveyNumber = ?", @surveynumber ).each do |survey| #2

        @NumberOfQuotas = survey.SurveyQuotas.length-1
        print '************ The Number of Quota IDs in this survey are more than 1: ', @NumberOfQuotas+1
        puts
        print '************ Lets examine if there are any Total+Quotas (k) open for this user'
        puts

        # each of j surveys specifies k quotas each
        
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
          
          if (user.country == '9') && (user.SurveysWithMatchingQuota.uniq.length >= 7) then
            @foundtopsurveyswithquota = true
          else
            if ((user.country == '5') || (user.country == '6')) && (user.SurveysWithMatchingQuota.uniq.length >= 4)
              @foundtopsurveyswithquota = true
            else
              #do nothing
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
                  print 'ZIPS: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                  puts
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
                  print 'ZIPS: ', survey.SurveyQuotas[k]["Questions"][l].values_at("PreCodes")
                  puts
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
            
            if (user.country == '9') && (user.SurveysWithMatchingQuota.uniq.length >= 7) then
              @foundtopsurveyswithquota = true
            else
              if ((user.country == '5') || (user.country == '6')) && (user.SurveysWithMatchingQuota.uniq.length >= 4)
                @foundtopsurveyswithquota = true
              else
                #do nothing
              end
            end

          else
            print 'Quota in survey number = is not open for this user: ', @surveynumber
            puts
          end
          
          
          
        else #5          
          if totalquotaexists == false then
            #do nothing
          else
            # NumberOfQuotas (k) is 0 i.e. there are no quotas specified but totalquotacount exists.
            # The survey is open to All, provided there is need for respondents specified in Total
            puts '************* Adding survey to list of eligible quotas even though no quotas specified but Totalquotaexists.'
            user.SurveysWithMatchingQuota << @surveynumber
            
            if (user.country == '9') && (user.SurveysWithMatchingQuota.uniq.length >= 7) then
              @foundtopsurveyswithquota = true
            else
              if ((user.country == '5') || (user.country == '6')) && (user.SurveysWithMatchingQuota.uniq.length >= 4)
                @foundtopsurveyswithquota = true
              else
                #do nothing
              end
            end
            
          end  
        end #5 if there is quota specified in k = 0 (total) or more (other IDs)
          
          
        end  #2 End reviewing quotas of a |survey|
      
      else
      end #3 if @foundtopsurveyswithquota = false
       
      end  #1 End j - going through the list of qualified surveys
        
    end #0 End 'if' user did qualify for any survey(s)
    
    
    
      # Lets save the survey numbers that the user meets the quota requirements for in this user's record of database in rank order
      
      if (user.SurveysWithMatchingQuota.empty?) then
        p '******************** USERRIDE: No Surveys matching quota were found in Fulcrum'
#        redirect_to '/users/nosuccess'
#        return
      else       
        user.SurveysWithMatchingQuota = user.SurveysWithMatchingQuota.uniq
        print '*************** List of Fulcrum surveys where quota is available:', user.SurveysWithMatchingQuota
        puts
      end
      
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
      print '******************** UserID is BLACKLISTED: ', user.user_id
      puts
      redirect_to '/users/nosuccess'
      return
    else
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
    
    
    # removing any blank entries
    if user.SupplierLink !=nil then
      user.SupplierLink.reject! { |c| c == nil}
    else
    end


    # Queue up additional surveys from P2S or others. First calculate teh additional values to be attached.
    
    @client = Network.find_by name: "P2S"
    if @client.status = "ACTIVE" then
      @SUBID = @client.netid+user.user_id
    
      print "**************** P2S @SUID = ", @SUBID
      puts

      if user.gender == '1' then
        @p2s_gender = "m"
      else
        @p2s_gender = "f"
      end
      
      # p2s additional values

      if user.country=="9" then 
        @p2s_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP
      else
        if user.country=="6" then
          @p2s_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP
        else
          if user.country=="5" then
            @p2s_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP
          else
            if user.country=="7" then
              @p2s_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP
            else
              puts "*************************************** P2S: Find out why country code is not correctly set"
              @p2s_AdditionalValues = 'age='+user.age+'&gender='+@p2s_gender+'&zip_code='+user.ZIP
              return
            end
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

    else
      # do nothing for P2S
    end
    
    # Save the list of SupplierLinks in user record
    user.save

    # Start the ride
    if (@netstatus == "INTTEST") then
      @PID = 'test'
    else
      @PID = user.user_id
    end
    
    if user.country=="9" then 
      @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&ZIP='+user.ZIP+'&HISPANIC='+user.ethnicity+'&ETHNICITY='+user.race+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_US='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.householdcomp.to_s
    else
      if user.country=="6" then
        @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&ZIP_Canada='+user.ZIP+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_INT='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.householdcomp.to_s
      else
        if user.country=="5" then
          @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&Fulcrum_ZIP_AU='+user.ZIP+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_INT='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.householdcomp.to_s
        else
          if user.country=="7" then
            @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&Fulcrum_ZIP_IN='+user.ZIP+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_INT='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.householdcomp.to_s
          else
            puts "*************************************** UseRide: Find out why country code is not correctly set"
            @AdditionalValues = '&AGE='+user.age+'&GENDER='+user.gender+'&STANDARD_EDUCATION='+user.eduation+'&STANDARD_HHI_INT='+user.householdincome+'&STANDARD_EMPLOYMENT='+user.householdcomp.to_s
            return
          end
        end
      end
    end    
    
    @parsed_user_agent = UserAgent.parse(user.user_agent)
    
    print "*************************************** UseRide: User platform is: ", @parsed_user_agent.platform
    puts
    
    if @parsed_user_agent.platform == 'iPhone' then
      
      @MS_is_mobile = '&MS_is_mobile=true'
      p "*************************************** UseRide: MS_is_mobile is set TRUE"
      
    else
      @MS_is_mobile = '&MS_is_mobile=false'
      p "*************************************** UseRide: MS_is_mobile is set FALSE"
      
    end


    if user.SupplierLink[0] == @p2sSupplierLink then
      
      print '*************** User will be sent to P2S router as no other surveys are availabe: ', user.SupplierLink[0]
      puts
      
      @EntryLink = user.SupplierLink[0]
      user.SupplierLink = user.SupplierLink.drop(1)
      user.save
      redirect_to @EntryLink
      
    else
      
      print '***************** User will be sent to this survey: ', user.SupplierLink[0]+@PID+@AdditionalValues+@MS_is_mobile
      puts
    
      @EntryLink = user.SupplierLink[0]+@PID+@AdditionalValues+@MS_is_mobile    
      user.SupplierLink = user.SupplierLink.drop(1)
      user.save
      redirect_to @EntryLink
      
    end # if user.SupplierLink[0] == @p2sSupplierLink then
    
  end
  

  # Sample survey pages control logic (p0 to success)
  
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
    
    user.SurveysCompleted["TESTSURVEY"] = [0, Time.now, user.clickid, user.netid]
    user.save
    
    redirect_to '/users/successful'
  end

end