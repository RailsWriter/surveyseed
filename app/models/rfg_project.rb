class RfgProject < ActiveRecord::Base
  serialize :datapoints, Array
  serialize :quotas, Array  
end
