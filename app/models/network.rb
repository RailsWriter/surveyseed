class Network < ActiveRecord::Base
  serialize :testcompletes, Hash
  serialize :completes, Hash
end
