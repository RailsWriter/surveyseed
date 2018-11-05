class NetworksController < ApplicationController
  def new
  end

  def create

    if params[:networks][:email] == "pm@aanicca.com" && params[:networks][:password] == "revenue" then
      # Log the user in and redirect to the user's show page.
      print "*********** email and password matched = ", params[:networks][:email], params[:networks][:password], " **************"
      puts
      @sessionId = params[:networks][:session_id]
      n=Network.find_by netid: "Na34dAasIY09muLqxd59A"
      n.Flag5 = @sessionId.to_s
      n.save
      redirect_to '/networks/KETSCIdashboard'
    else
      # Create an error message.
      print "*********** email and password did not match = ", params[:networks][:email], ',', params[:networks][:password], " **************"
      puts
      flash[:alert] = "Please check your email address or password."
      redirect_to '/networks/login'
    end
  end
  
  def destroy
  end
end
