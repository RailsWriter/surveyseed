class Survey < ActiveRecord::Base
  serialize :QualificationAgePreCodes, Array
  serialize :QualificationGenderPreCodes, Array
  serialize :QualificationZIPPreCodes, Array
  serialize :QualificationHHIPreCodes, Array
  serialize :QualificationEducationPreCodes, Array
  serialize :QualificationHHCPreCodes, Array
  serialize :QualificationEthnicityPreCodes, Array
  serialize :QualificationRacePreCodes, Array
  serialize :QuotaAgePreCodes, Array
  serialize :QuotaGenderPreCodes, Array
  serialize :QuotaZIPPreCodes, Array
  serialize :QuotaHHIPreCodes, Array
  serialize :QuotaEducationPreCodes, Array
  serialize :QuotaHHCPreCodes, Array
  serialize :QuotaEthnicityPreCodes, Array
  serialize :QuotaRacePreCodes, Array
  serialize :SupplierLinks, Hash
  
  def new
  end
  
end
