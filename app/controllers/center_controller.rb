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
      
    
    def RFGProjects_US
      
      @projects = RfgProject.where("country = ?", "US").order(projectEPC: :desc).order(epc: :desc).each
    
      respond_to do |format|
        format.html # home.html.erb
        format.json { render json: @projects }
      end      
    end

    def show_surveys_US
      @projects = RfgProject.where("country = ?", "US").each  
    end
  
  
    def RFGProjects_CA
      
      @projects = RfgProject.where("country = ?", "CA").order(projectEPC: :desc).order(epc: :desc).each
    
      respond_to do |format|
        format.html # home.html.erb
        format.json { render json: @projects }
      end      
    end

    def show_surveys_CA
      @projects = RfgProject.where("country = ?", "CA").each  
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