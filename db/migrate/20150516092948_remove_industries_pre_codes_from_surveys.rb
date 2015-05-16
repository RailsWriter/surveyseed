class RemoveIndustriesPreCodesFromSurveys < ActiveRecord::Migration
  def change
    remove_column :surveys, :QualificationIndustriesPreCodes, :text
  end
end
