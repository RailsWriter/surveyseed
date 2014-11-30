class Survey < ActiveRecord::Base
  
  serialize :QualificationAgePreCodes, Array
  serialize :QualificationGenderPreCodes, Array
  serialize :QualificationZIPPreCodes, Array
  serialize :QualificationHHIPreCodes, Array
  serialize :QualificationAgePreCodes, Array
  serialize :QualificationEducationPreCodes, Array
  serialize :QualificationHHCPreCodes, Array
  serialize :QualificationEthnicityPreCodes, Array
  serialize :QualificationRacePreCodes, Array
  serialize :SurveyQuotas, Array
  serialize :SupplierLink, Hash
  
end
