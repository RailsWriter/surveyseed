class User < ActiveRecord::Base    
  serialize :attempts_time_stamps_array, Array
  serialize :QualifiedSurveys, Array
  serialize :SurveysWithMatchingQuota, Array
  serialize :SupplierLink, Array
  serialize :SurveysAttempted, Array
  serialize :SurveysCompleted, Hash
  
  serialize :children, Array
  serialize :industries, Array

end