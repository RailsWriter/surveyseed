class CenterController < ApplicationController

  def surveys_US
    @surveys = Survey.where("CountryLanguageID = ?", '9').order( "SurveyGrossRank").each
    
    respond_to do |format|
      format.html # home.html.erb
      format.json { render json: @surveys }
    end      
  end

  def show_surveys_US
    @surveys = Survey.where("CountryLanguageID = ?", '9').each  
  end
  
  
  def surveys_AU
    @surveys = Survey.where("CountryLanguageID = ?", '5').order( "SurveyGrossRank").each
    
    respond_to do |format|
      format.html # home.html.erb
      format.json { render json: @surveys }
    end      
  end

  def show_surveys_AU
    @surveys = Survey.where("CountryLanguageID = ?", '5').each  
  end
  
  def surveys_CA
    @surveys = Survey.where("CountryLanguageID = ?", '6').order( "SurveyGrossRank").each
    
    respond_to do |format|
      format.html # home.html.erb
      format.json { render json: @surveys }
    end      
  end

  def show_surveys_CA
    @surveys = Survey.where("CountryLanguageID = ?", '6').each  
  end
  
  def surveys_IN
    @surveys = Survey.where("CountryLanguageID = ?", '7').order( "SurveyGrossRank").each
    
    respond_to do |format|
      format.html # home.html.erb
      format.json { render json: @surveys }
    end      
  end

  def show_surveys_IN
    @surveys = Survey.where("CountryLanguageID = ?", '7').each  
  end
  
  
  def users_US  
    @users = User.where("country = ?", '9').last(100).reverse.each

      respond_to do |format|
        format.html # users.html.erb
        format.json { render json: @users }
      end
  end
  
  def show_users_US
    @users = User.where("country = ?", '9').each
  end
  
  def users_AU  
    @users = User.where("country = ?", '5').last(100).reverse.each

      respond_to do |format|
        format.html # users.html.erb
        format.json { render json: @users }
      end
  end
  
  def show_users_AU
    @users = User.where("country = ?", '5').each
  end
    
  def users_CA  
    @users = User.where("country = ?", '6').last(100).reverse.each

      respond_to do |format|
        format.html # users.html.erb
        format.json { render json: @users }
      end
  end
  
  def show_users_CA
    @users = User.where("country = ?", '6').each
  end

  def users_IN  
    @users = User.where("country = ?", '7').last(100).reverse.each

      respond_to do |format|
        format.html # users.html.erb
        format.json { render json: @users }
      end
  end

  def show_users_IN
    @users = User.where("country = ?", '7').each
  end
  
  def RFGProjects_CA
    
    @projects = RfgProject.where("country = ?", "CA").order(estimatedIR: :desc).order(projectEPC: :desc).each
  
    respond_to do |format|
      format.html # home.html.erb
      format.json { render json: @projects }
    end      
  end

  def show_projects_CA
    @projects = RfgProject.where("country = ?", "CA").each  
  end
  
  def RFGProjects_US
    
    @projects = RfgProject.where("country = ?", "US").order(estimatedIR: :desc).order(projectEPC: :desc).each
  
    respond_to do |format|
      format.html # home.html.erb
      format.json { render json: @projects }
    end      
  end

  def show_projects_US
    @projects = RfgProject.where("country = ?", "US").each  
  end  
  
  def RFGProjects_AU
    
    @projects = RfgProject.where("country = ?", "AU").order(estimatedIR: :desc).order(projectEPC: :desc).each
  
    respond_to do |format|
      format.html # home.html.erb
      format.json { render json: @projects }
    end      
  end

  def show_projects_AU
    @projects = RfgProject.where("country = ?", "AU").each  
  end


  def adhoc_surveys
    @a_surveys = Adhoc.where("SurveyNumber > ?", 0).each
  
    respond_to do |format|
      format.html # home.html.erb
      format.json { render json: @a_surveys }
    end      
  end

  def show_adhoc_surveys
    @a_surveys = Adhoc.where("SurveyNumber > ?", 0).each
  end
  

  def draft_survey

    if params[:newAdhocSurvey] != nil then
      print "****************** Received draft_survey ", params[:newAdhocSurvey]
      puts

      respond_to do |format|
        format.html # home.html.erb
        format.json { render json: { message: "newAdhocSurvey received" } }
      end 


      a=Adhoc.new
      a.SurveyName = params[:newAdhocSurvey]["SurveyName"]
      a.SurveyNumber = 1000+Adhoc.count+2
      a.SupplierLink = params[:newAdhocSurvey]["LiveLink"]
      a.LengthOfInterview = params[:newAdhocSurvey]["LOI"]

      
      if params[:newAdhocSurvey]["Quotas"][0]["Country"] == "US" then
        a.CountryLanguageID=9
      else
        if params[:newAdhocSurvey]["Quotas"][0]["Country"] == "CA" then
          a.CountryLanguageID=6
        else
          if params[:newAdhocSurvey]["Quotas"][0]["Country"] == "AU" then
            a.CountryLanguageID=5
          else
          end
        end
      end
      a.TotalRemaining = params[:newAdhocSurvey]["Quotas"][0]["NoOfCompletes"].to_i
      a.CPI = params[:newAdhocSurvey]["Quotas"][0]["CPI"].to_f
      a.QualificationAgePreCodes = params[:newAdhocSurvey]["Quotas"][0]["Age"]
      if params[:newAdhocSurvey]["Quotas"][0]["Gender"] == "M" then
        a.QualificationGenderPreCodes= ["1"]
      else
        if params[:newAdhocSurvey]["Quotas"][0]["Gender"] == "F" then
          a.QualificationGenderPreCodes= ["2"]
        else
          a.QualificationGenderPreCodes= ["ALL"]
        end
      end
      if params[:newAdhocSurvey]["Quotas"][0]["Zip"] == nil then
        a.QualificationZIPPreCodes = ["ALL"]
      else
        a.QualificationZIPPreCodes = params[:newAdhocSurvey]["Quotas"][0]["Zip"]
      end
      a.QualificationEducationPreCodes = params[:newAdhocSurvey]["Quotas"][0]["stdEdu"]
      a.QualificationHHIPreCodes = params[:newAdhocSurvey]["Quotas"][0]["stdHiUS"]
      a.QualificationChildrenPreCodes = params[:newAdhocSurvey]["Quotas"][0]["ChildAgeGender"]
      a.QualificationEmploymentPreCodes = params[:newAdhocSurvey]["Quotas"][0]["stdEmployment"]
      a.QualificationDMAPreCodes = params[:newAdhocSurvey]["Quotas"][0]["DMA"]
      a.QualificationStatePreCodes = params[:newAdhocSurvey]["Quotas"][0]["State"]
      a.QualificationRegionPreCodes = params[:newAdhocSurvey]["Quotas"][0]["Region"]
      
      a.Screener1 = params[:newAdhocSurvey]["Question1"]
      a.Screener1Resp = params[:newAdhocSurvey]["QuestionAns1"]
      # if params[:newAdhocSurvey]["SurveyStatus"] == "Draft" then
      if params[:newAdhocSurvey]["SurveyStatus"] == "Launch" then
        a.SurveyStillLive=true
      else
        a.SurveyStillLive=false
      end
      a.save
    else

      respond_to do |format|
        format.html # home.html.erb
        format.json { render json: { message: "No newAdhocSurvey received" } }
      end 

      p "***************** Nothing was received as draft_survey **************"
    end
  end

  def panelStats
    @winner = User.where.not('password = ?', "").each
  end

  def addPanelistAction
    # Flash Admin to pay attention
    # flash[:alert] = "Must use INCOGNITO MODE"
    if (params[:emailid].empty? == false) then
      if (User.where('emailId = ?', params[:emailid]).exists?) then
        #do nothing as panelist already exists
        p "****DEBUG ********** addPanelist: The user is already a Panelist *****************"
        redirect_to '/users/alreadyPanelist'
      else
        ip_address = request.remote_ip
        # session_id = session.id (otherwise all added panelist will have same sessionId and join_panel will have hard time distinguishing them.)
        netid = "KetsciPanel"
        clickid = "ADMIN_PANELIST"

        user=User.new        
        user.QualifiedSurveys = Array.new
        user.SurveysWithMatchingQuota = Array.new
        user.SupplierLink = Array.new
        user.user_agent = env['HTTP_USER_AGENT']
        # user.session_id = session_id
        user.user_id = SecureRandom.urlsafe_base64
        user.ip_address = ip_address
        user.tos = false
        user.watch_listed=false
        user.black_listed=false
        user.number_of_attempts_in_last_24hrs=0       
        user.netid = netid
        user.clickid = clickid 
        user.emailId = params[:emailid]
        user.password = 'Ketsci'+user.user_id[0..3]
        user.userType='1'
        user.redeemRewards='1'
        user.surveyFrequency = '1'
        user.save
        print "***************** Admin successfully created a new panelist: ", user
        puts
        # Sends email to user when panelist is created. 
        # todo: Remove the If condition before going live.
        if params[:commit] == "SendWelcomeEmail" && user.emailId == 'akhtarjameel@gmail.com' then
          begin
            p "========================================================Sending Welcome MAIL to new Leads Panelist ================================"
            PanelMailer.welcome_email(user).deliver_now
            rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
            print "Problem sending Welcome mail to ", emailId, "due to message: ", e.message
            puts
          end
        else
          #do nothing
        end        
        redirect_to '/users/thanks' # todo: replace by a success page in center controller for adding panelist
      end
    else
      p "************** The Admin wants to add a panelist but did not enter an emailid => Retry *****************"
      redirect_to '/center/addPanelist'  # retry
    end    
  end
   
end