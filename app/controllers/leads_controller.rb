class LeadsController < ApplicationController
  
  def home
    require 'mixpanel-ruby'
    tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')
        
    @lead = Lead.new
    @ip_address = request.remote_ip
			
    tracker.track(@ip_address, 'LeadsPage')
    
  end

  # def donate
  #   require 'mixpanel-ruby'
  #   tracker = Mixpanel::Tracker.new('e5606382b5fdf6308a1aa86a678d6674')

  #   @ip_address = request.remote_ip
  #   @session_id = session.id
  #   @netid = "KsAnLL23qacAHoi87ytr45bhj8"

  #   @user = User.where("ip_address = ? AND session_id = ?", @ip_address, @session_id).first
  #   if (@user!=nil)
  #     # p '********* LEAD: EXISTING USER'
  #     # refactor: what if a user comes back from a non-charity network. Other network is erased/lost.
  #     @user.netid = @netid
  #     redirect_to '/users/qq12'
  #   else
  #     # p 'LEAD: NEW USER'
  #     redirect_to '/users/newCharity'
  #   end

  #   tracker.track(@ip_address, 'Charity')
  # end
  
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
