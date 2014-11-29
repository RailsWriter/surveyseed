class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.string :SurveyName
      t.integer :SurveyNumber
      t.string :SurveySID
      t.string :AccountName
      t.integer :CountryLanguageID
      t.integer :LengthOfInterview
      t.float :BidIncidence
      t.integer :Conversion
      t.float :CPI
      t.datetime :FieldEndDate
      t.integer :IndustryID
      t.integer :StudyTypeID
      t.integer :OverallCompletes
      t.integer :TotalRemaining
      t.integer :CompletionPercentage
      t.string :SurveyGroup
      t.integer :BidLengthOfInterview
      t.integer :TerminationLengthOfInterview
      t.string :IsTrueSample
      t.integer :SurveyMobileConversion
      t.integer :SurveyQuotaCalcTypeID
      t.integer :SampleTypeID
      t.text :QualificationAgePreCodes
      t.text :QualificationGenderPreCodes
      t.text :QualificationZIPPreCodes
      t.text :QualificationHHIPreCodes
      t.text :QualificationEducationPreCodes
      t.text :QualificationHHCPreCodes
      t.text :QualificationEthnicityPreCodes
      t.text :QualificationRacePreCodes
      t.text :SurveyQuotas
      t.string :SurveyStatusCode
      t.boolean :SurveyStillLive
      t.integer :SurveyGrossRank
      t.integer :SurveyExactRank
      t.text :SupplierLink

      t.timestamps null: false
    end
  end
end
