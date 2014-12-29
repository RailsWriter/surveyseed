class LeadsController < ApplicationController
  
  def home
    require 'mixpanel-ruby'
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
        
    @lead = Lead.new
    @ip_address = request.remote_ip
			
    tracker.track(@ip_address, 'Home Control')
    
  end
  
  def create
    @lead = Lead.new(lead_params)
    if @lead.save
      # Handle a successful save.
      flash[:alert] = "Thanks, we will be in touch soon!"
      redirect_to '/'
    else
      render 'home'
    end
  end
    
  private
    
    def lead_params
      params.require(:lead).permit(:name, :email, :phone, :message)
    end
end
