class CreateAdhocs < ActiveRecord::Migration
  def change
    create_table :adhocs do |t|
      t.string :SurveyName
      t.integer :SurveyNumber
      t.integer :CountryLanguageID
      t.integer :LengthOfInterview
      t.integer :Conversion
      t.float :CPI
      t.integer :OverallCompletes
      t.integer :TotalRemaining
      t.integer :SurveyMobileConversion
      t.text :QualificationAgePreCodes
      t.text :QualificationGenderPreCodes
      t.text :QualificationZIPPreCodes
      t.text :QualificationHHIPreCodes
      t.text :QualificationEducationPreCodes
      t.text :QualificationHHCPreCodes
      t.text :QualificationEthnicityPreCodes
      t.text :QualificationRacePreCodes
      t.text :QualificationEmploymentPreCodes
      t.text :QualificationPIndustryPreCodes
      t.text :QualificationDMAPreCodes
      t.text :QualificationStatePreCodes
      t.text :QualificationRegionPreCodes
      t.text :QualificationDivisionPreCodes
      t.text :QualificationJobTitlePreCodes
      t.text :QualificationChildrenPreCodes
      t.text :SurveyQuotas
      t.boolean :SurveyStillLive
      t.integer :SurveyGrossRank
      t.integer :SurveyExactRank
      t.text :SupplierLink
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :FailureCount
      t.integer :OverQuotaCount
      t.integer :NumberOfAttemptsAtLastComplete
      t.float :GEPC
      t.float :KEPC
      t.float :TCR
      t.string :Label
      t.datetime :LastModified

      t.timestamps null: false
    end
  end
end
