class RedirectsController < ApplicationController
  def status
    
    case params[:status] 
      
      when "1"
        # DefaultLink: https://www.ketsci.com/redirects/status?status=1&PID=[%PID%]&cq=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        @PID = params[:PID]
        p 'PID = ', @PID
        @CQS = params[:cqs]
        p 'CLIENT_QUERYSTRING = ', @CQS
        @url = request.original_url
        p 'url =', @url
        redirect_to '/users/show?status=1'
        
        # save in User and Survey tables

      when "2"
        # SuccessLink: https://www.ketsci.com/redirects/status?status=2&PID=[%PID%]&cq=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]&cost=[%COST%]
        
        p 'Suceess'
        # save in User and Survey tables

        @PID = params[:PID]
        user = User.find_by user_id: @PID
  #      user.SurveysCompleted << params[:tsfn]
        survey = Survey.find_by SurveyNumber: params[:tsfn]
        survey.CompletedBy = @PID

        redirect_to '/users/show?status=2'

      when "3"
        # FailureLink: https://www.ketsci.com/redirects/status?status=3&PID=[%PID%]&cq=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'Failure'
        
        # save in User and Survey tables
      
        @PID = params[:PID]
        user = User.find_by user_id: @PID
  #      user.SurveysAttempted << params[:tsfn]
        SupplierLink = SupplierLink.drop(1)
        puts 'Remaining surveys to attempt:', SupplierLink
        redirect_to user.SupplierLink[0]+@PID
        
        redirect_to '/users/show?status=3'
        
        
      when "4"
        # OverQuotaLink: https://www.ketsci.com/redirects/status?status=4&PID=[%PID%]&cq=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'OQuota'
      
        # save in User and Survey tables
        
        @PID = params[:PID]
        user = User.find_by user_id: @PID
  #      user.SurveysAttempted << params[:tsfn]

        SupplierLink = SupplierLink.drop(1)
        puts 'Remaining surveys to attempt:', SupplierLink
        redirect_to user.SupplierLink[0]+@PID
             
        redirect_to '/users/show?status=4'
      
    
      when "5"
        # QualityTerminationLink: https://www.ketsci.com/redirects/status?status=5&PID=[%PID%]&cq=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'QTerm'

        # save in User and Survey tables
        @PID = params[:PID]
        user = User.find_by user_id: @PID
#        user.blacklisted = true

        redirect_to '/users/show?status=5'
        
    end
    
  end
end
