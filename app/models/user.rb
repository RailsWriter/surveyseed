class User < ActiveRecord::Base    
  serialize :attempts_time_stamps_array, Array
end