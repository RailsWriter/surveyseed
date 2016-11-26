class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  add_flash_types :error, :alert

  # Added from http://stackoverflow.com/questions/17858178/allow-anything-through-cors-policy?answertab=votes#tab-top
  before_filter :current_user, :cors_preflight_check
  after_filter :cors_set_access_control_headers

# For all responses in this controller, return the CORS access control headers.

def cors_set_access_control_headers
  headers['Access-Control-Allow-Origin'] = '*'
  headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
  headers['Access-Control-Request-Method'] = '*'
  headers['Access-Control-Allow-Headers'] = '*'
  headers['Access-Control-Max-Age'] = "1728000"
end

# If this is a preflight OPTIONS request, then short-circuit the
# request, return only the necessary headers and return an empty
# text/plain.

def cors_preflight_check
  if request.method == :options
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = '*'
    headers['Access-Control-Max-Age'] = '1728000'
    render :text => '', :content_type => 'text/plain'
  end
end
  private
  # get the user currently logged in
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

end
