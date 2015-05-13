class AddIndustriesPreCodesToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :QualificationIndustriesPreCodes, :text
  end
end
