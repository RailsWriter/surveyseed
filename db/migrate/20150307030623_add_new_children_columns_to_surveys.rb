class AddNewChildrenColumnsToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :QualificationChildrenPreCodes, :text
  end
end
