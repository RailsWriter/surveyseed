class CenterController < ApplicationController
  def home
    
    @surveys = Survey.where("SurveyGrossRank < ?", 21).order( "SurveyGrossRank" ).each
    
    respond_to do |format|
          format.html # home.html.erb
          format.json { render json: @surveys }
    end
  end
  

  def show
    @surveys = Survey.where("SurveyGrossRank < ?", 21).each  
  end

end