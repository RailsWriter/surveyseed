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

        if params[:PID] = 'test' then
          redirect_to 'https://www.ketsci.com/redirects/success'
        else
          # save attempt info in User and Survey tables
          
          user = User.find_by user_id: params[:PID]
          user.SurveysAttempted << params[:tsfn]
#         Save completed survey info in a hash with survey number as key {params[:tsfn] => [params[:cost], params[:tsfn]], ..}
# @a=params[:tsfn]
# @b=[params[:cost], params[:tsfn]]
          user.SurveysCompleted.store("params[:tsfn]"=>[params[:cost], params[:tsfn]])

          survey = Survey.find_by SurveyNumber: params[:tsfn]
          p 'Just completed survey:', survey.SurveyNumber, 'by user_id:', user.user_id
#         survey.CompletedBy = params[:PID]
#         survey.ActualTimeInSurvey = params[:tis]

          # Give user chance to take another survey
          if (user.SupplierLink) then
            redirect_to user.SupplierLink[0]+@PID
          else
            redirect_to 'https://www.ketsci.com/redirects/failure?&SUCCESS'
          end
        end

      when "3"
        # FailureLink: https://www.ketsci.com/redirects/status?status=3&PID=[%PID%]&cqs=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        # This link is used when there are no ways to get user to do a survey e.g. if they are under age or no they do not qualify for any surveys.
        
        p 'Failure'

# turn to 'test' be true on launch        
        if params[:PID] != 'test' then
          redirect_to 'https://www.ketsci.com/redirects/failure&FAILED=1'
        else
#          render json: 'FAILED'
          # save attempt info in User and Survey tables
#          user = User.find_by user_id: params[:PID]          
#          user.SurveysAttempted << params[:tsfn]

          user = User.last
          user.ZIP=99999
          redirect_to 'https://www.ketsci.com/redirects/failure?&FAILED=2'
        end
        
      when "4"
        # OverQuotaLink: https://www.ketsci.com/redirects/status?status=4&PID=[%PID%]&cqs=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'OQuota'

# turn to t'test' be true on launch 
        if params[:PID] != 'test' then
          redirect_to 'https://www.ketsci.com/redirects/overquota'
        else
          render json: 'OQ'
          user = User.find_by user_id: params[:PID]
          
          # save attempt info in User and Survey tables
          user.SurveysAttempted << params[:tsfn]
          
          # Give user chance to take another survey
#         if (user.SupplierLink) then
#            redirect_to user.SupplierLink[0]+@PID
#          else
#            redirect_to 'https://www.ketsci.com/redirects/failure'
#          end
        end
    
      when "5"
        # QualityTerminationLink: https://www.ketsci.com/redirects/status?status=5&PID=[%PID%]&cqs=[%CLIENT_QUERYSTRING%]&frid=[%fedResponseID%]&tis=[%TimeInSurvey%]&tsfn=[%TSFN%]
        
        p 'QTerm'

        if params[:PID] = 'test' then
          redirect_to 'https://www.ketsci.com/redirects/qterm'
        else
          # save attempt info in User and Survey tables
          user = User.find_by user_id: params[:PID]
          user.SurveysAttempted << params[:tsfn]
          user.black_listed = true
          redirect_to 'https://www.ketsci.com/redirects/qterm'
        end
    end
    
  end
  
end
