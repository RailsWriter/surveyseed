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
      redirect_to '/leads/thanks'
    else
      render 'home'
    end
  end
    
  private
    
    def lead_params
      params.require(:lead).permit(:name, :email, :message)
    end
end
