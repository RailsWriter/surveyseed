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
  serialize :CompletedBy, Hash
  serialize :SupplierLink, Hash
  
  
  serialize :QualificationEmploymentPreCodes, Array
  serialize :QualificationPIndustryPreCodes, Array
  serialize :QualificationDMAPreCodes, Array
  serialize :QualificationStatePreCodes, Array
  serialize :QualificationRegionPreCodes, Array
  serialize :QualificationDivisionPreCodes, Array
  
end
