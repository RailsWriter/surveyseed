class ChangeColumn < ActiveRecord::Migration
  def change
    change_column :surveys, :QualificationZIPPreCodes, :text, :limit => 1000000
  end
end
