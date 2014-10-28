class LeadsController < ApplicationController
  def home
      @lead = Lead.new
  end

   def thanks
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
