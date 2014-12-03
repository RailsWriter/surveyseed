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
        redirect_to 'http://www.apple.com'
        
        
        # save in User and Survey tables

      when "2"
        # SuccessLink: https://www.ketsci.com/redirects/status?status=2&PID=[%PID%]&cq=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]&cost=[%COST%]
        
        p 'Suceess'
        # save in User and Survey tables
        redirect_to 'http://www.google.com'

      when "3"
        # FailureLink: https://www.ketsci.com/redirects/status?status=3&PID=[%PID%]&cq=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'Failure'
        redirect_to 'http://www.cnn.com'
        
        # save in User and Survey tables
      
      when "4"
        # OverQuotaLink: https://www.ketsci.com/redirects/status?status=4&PID=[%PID%]&cq=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'OQuota'
        redirect_to 'http://www.youtube.com'
        
        # save in User and Survey tables
    
      when "5"
        # QualityTerminationLink: https://www.ketsci.com/redirects/status?status=5&PID=[%PID%]&cq=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'QTerm'
        redirect_to 'http://www.nytimes.com'
        
        # save in User and Survey tables
    end
    
  end
end
