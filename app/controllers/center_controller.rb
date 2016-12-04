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
      print "****************** Received draft_survey", params[:newAdhocSurvey]
      puts

      respond_to do |format|
        format.html # home.html.erb
        format.json { render json: { message: "newAdhocSurvey received" } }
      end 

      a=Adhoc.new
      a.SurveyName = params[:newAdhocSurvey]["SurveyName"]
      a.SurveyNumber = 1000+Adhoc.count+2
      # a.CountryLanguageID = params[:newAdhocSurvey]["CountryLanguageID"]
      a.LengthOfInterview = params[:newAdhocSurvey]["LengthOfInterview"]
      a.TotalRemaining = params[:newAdhocSurvey]["NoOfCompletes"].to_i
      a.CPI = params[:newAdhocSurvey]["CPI"].to_f
      # a.QualificationAgePreCodes = params[:newAdhocSurvey]["QualificationAgePreCodes"]
      # a.QualificationGenderPreCodes = params[:newAdhocSurvey]["QualificationGenderPreCodes"]
      # a.QualificationZIPPreCodes = params[:newAdhocSurvey]["QualificationZIPPreCodes"]
      # a.QualificationEducationPreCodes = params[:newAdhocSurvey]["QualificationEducationPreCodes"]
      # a.QualificationHHIPreCodes = params[:newAdhocSurvey][:stdHiUS][:stdHiUSCode]
      # a.QualificationChildrenPreCodes = params[:newAdhocSurvey]["QualificationChildrenPreCodes"]
      # a.QualificationEmploymentPreCodes = params[:newAdhocSurvey]["QualificationEmploymentPreCodes"]
      a.QualificationDMAPreCodes = params[:newAdhocSurvey]["DMA"]
      a.QualificationStatePreCodes = params[:newAdhocSurvey]["State"]
      a.QualificationRegionPreCodes = params[:newAdhocSurvey]["Region"]
      a.SurveyStillLive=false
      a.SupplierLink = params[:newAdhocSurvey]["LiveLink"]
      a.Screener1 = params[:newAdhocSurvey]["Question1"]
      a.Screener1Resp = params[:newAdhocSurvey]["QuestionAns1"]
      a.save
    else

      respond_to do |format|
        format.html # home.html.erb
        format.json { render json: { message: "newAdhocSurvey received" } }
      end 

      p "***************** Nothing was received as draft_survey **************"
    end
  end
    
        
#    def alllNets
      
#      @networks = Network.where("status = ?", "ACTIVE").last(10).each
    
#      respond_to do |format|
#        format.html # home.html.erb
#        format.json { render json: @networks }
#      end      
#    end

#    def show_networks
#      @networks = Network.where("status = ?", "ACTIVE").each
#    end
   
end