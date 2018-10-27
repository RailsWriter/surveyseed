class NetworksController < ApplicationController
  def new
  end

  def create
    if params[:networks][:email] == "a@b.com" && params[:networks][:password] == "a@b.com" then
      # Log the user in and redirect to the user's show page.
      print "*********** email and password matched = ", params[:networks][:email], params[:networks][:password], " **************"
      puts
      redirect_to '/users/new'
    else
      # Create an error message.
      print "*********** email and password did not match = ", params[:networks][:email], params[:networks][:password], " **************"
      puts
      render 'networks/login'
    end
  end
  
  def destroy
  end
end
