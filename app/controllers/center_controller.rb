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
      a=Adhoc.new
      a.SurveyName = params[:newAdhocSurvey][SurveyName]
      a.SurveyNumber = 1000+Adhoc.count+1
      a.CountryLanguageID = params[:newAdhocSurvey][CountryLanguageID]
      a.LengthOfInterview = params[:newAdhocSurvey][LengthOfInterview]
      a.CPI = params[:newAdhocSurvey][CPI]
      a.QualificationAgePreCodes = params[:newAdhocSurvey][QualificationAgePreCodes]
      a.QualificationGenderPreCodes = params[:newAdhocSurvey][QualificationGenderPreCodes]
      a.QualificationZIPPreCodes = params[:newAdhocSurvey][QualificationZIPPreCodes]
      a.QualificationEducationPreCodes = params[:newAdhocSurvey][QualificationEducationPreCodes]
      a.QualificationHHIPreCodes = params[:newAdhocSurvey][QualificationHHIPreCodes]
      a.QualificationChildrenPreCodes = params[:newAdhocSurvey][QualificationChildrenPreCodes]
      a.QualificationEmploymentPreCodes = params[:newAdhocSurvey][QualificationEmploymentPreCodes]
      a.QualificationDMAPreCodes = params[:newAdhocSurvey][QualificationDMAPreCodes]
      a.QualificationStatePreCodes = params[:newAdhocSurvey][QualificationStatePreCodes]
      a.QualificationRegionPreCodes = params[:newAdhocSurvey][QualificationRegionPreCodes]
      a.SurveyStillLive=false
      a.save
    else
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