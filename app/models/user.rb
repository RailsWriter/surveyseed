class User < ActiveRecord::Base    
  serialize :attempts_time_stamps_array, Array
  serialize :QualifiedSurveys, Array
  serialize :SurveysWithMatchingQuota, Array
  serialize :SupplierLink, Array
end