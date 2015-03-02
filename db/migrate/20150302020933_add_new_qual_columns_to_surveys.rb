class AddNewQualColumnsToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :QualificationEmploymentPreCodes, :text
    add_column :surveys, :QualificationPIndustryPreCodes, :text
    add_column :surveys, :QualificationDMAPreCodes, :text
    add_column :surveys, :QualificationStatePreCodes, :text
    add_column :surveys, :QualificationRegionPreCodes, :text
    add_column :surveys, :QualificationDivisionPreCodes, :text
  end
end
