class RfgProject < ActiveRecord::Base
  serialize :datapoints, Array
  serialize :quotas, Array  
  serialize :CompletedBy, Hash
end
