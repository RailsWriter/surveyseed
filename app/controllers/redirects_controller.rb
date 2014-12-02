class RedirectsController < ApplicationController
  def status
    
    case params[:status] 
      
      when "1"
        # Default: http://www.ketsci.com/redirects/status?status=1&PID=[%PID%][%CLIENT_QUERYSTRING%]
        
        @PID = params[:PID]
        p 'PID = ', @PID
        @CQ = params[:CLIENT_QUERYSTRING]
        p 'CLIENT_QUERYSTRING = ', @CQ
        @url = request.original_url
        p 'url =', @url
        
        # save in User and Survey tables

      when "2"
        # Success: http://www.ketsci.com/redirects/status?status=2&PID=[%PID%][%CLIENT_QUERYSTRING%]
        
        p 'Suceess'
        # save in User and Survey tables
        redirect_to 'http://www.google.com'

      when "3"
        # Failure: http://www.ketsci.com/redirects/status?status=3&PID=[%PID%][%CLIENT_QUERYSTRING%]
        
        p 'Failure'
        
        # save in User and Survey tables
      
      when "4"
        # Over Quota: http://www.ketsci.com/redirects/status?status=4&PID=[%PID%][%CLIENT_QUERYSTRING%]
        
        p 'OQuota'
        
        # save in User and Survey tables
    
      when "5"
        # Quality Term: http://www.ketsci.com/redirects/status?status=5&PID=[%PID%][%CLIENT_QUERYSTRING%]
        
        p 'QTerm'
        
        # save in User and Survey tables
    end
    
  end
end
