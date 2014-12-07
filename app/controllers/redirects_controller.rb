class RedirectsController < ApplicationController
  def status
    
    case params[:status] 
      
      when "1"
        # DefaultLink: https://www.ketsci.com/redirects/status?status=1&PID=[%PID%]&cqs=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        @PID = params[:PID]
        p 'PID = ', @PID
        @CQS = params[:cqs]
        p 'CLIENT_QUERYSTRING = ', @CQS
        @url = request.original_url
        p 'url =', @url
        redirect_to 'https://www.ketsci.com/redirects/default'
        
        # save attempt info in User and Survey tables

      when "2"
        # SuccessLink: https://www.ketsci.com/redirects/status?status=2&PID=[%PID%]&cqs=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]&cost=[%COST%]
        
        p 'Suceess'
        # save attempt info in User and Survey tables

        @PID = params[:PID]
        user = User.find_by user_id: @PID
  #      user.SurveysCompleted << params[:tsfn]
        survey = Survey.find_by SurveyNumber: params[:tsfn]
  #     survey.SurveyCompltedBy = @PID

        redirect_to 'https://www.ketsci.com/redirects/success'

      when "3"
        # FailureLink: https://www.ketsci.com/redirects/status?status=3&PID=[%PID%]&cqs=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'Failure'
        
        # save attempt info in User and Survey tables
      
        @PID = params[:PID]
        
        if @PID = 'test' then
          redirect_to 'https://www.ketsci.com/redirects/failure'
        else
          # Give user chance to take another survey
          user = User.find_by user_id: @PID
          if (user.SupplierLink) then
            redirect_to user.SupplierLink[0]+@PID
          else
            redirect_to 'https://www.ketsci.com/redirects/default'
          en
        end
        
      when "4"
        # OverQuotaLink: https://www.ketsci.com/redirects/status?status=4&PID=[%PID%]&cqs=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'OQuota'
        
        # save attempt info in User and Survey tables
        
        @PID = params[:PID]
        
        if @PID = 'test' then
          redirect_to 'https://www.ketsci.com/redirects/overquota'
        else
          # Give user chance to take another survey
          user = User.find_by user_id: @PID
          if (user.SupplierLink) then
            redirect_to user.SupplierLink[0]+@PID
          else
            redirect_to 'https://www.ketsci.com/redirects/default'
          end
        end
    
      when "5"
        # QualityTerminationLink: https://www.ketsci.com/redirects/status?status=5&PID=[%PID%]&cqs=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'QTerm'

        # save attempt info in User and Survey tables
        
        @PID = params[:PID]
        user = User.find_by user_id: @PID
#        user.blacklisted = true

        redirect_to 'https://www.ketsci.com/redirects/qterm'
        
    end
    
  end
  
end
