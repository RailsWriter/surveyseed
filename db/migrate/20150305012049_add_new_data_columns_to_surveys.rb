class AddNewDataColumnsToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :QualificationJobTitlePreCodes, :text
  end
end
